// Rice theme reloader: a Noctis plugin of ~100 lines that exists for one reason.
//
// The desktop rice (rice.sh) renders the active colour theme into a Noctis *content
// pack* (plugins/rice.theme/themes/rice.json). Noctis applies a pack theme live when
// the pack changes, but it only re-reads packs at startup, on install, or when a pack
// is toggled in Settings; there is no file watcher and no API for it. This plugin
// adds the missing watcher: when anything under plugins/rice.theme changes it asks the
// plugin host to drop and re-load that one pack, exactly as Settings > Plugins >
// Install from file does for an update. Noctis then notices the same theme has new
// colours and recolours every window without a restart.
//
// The plugin API has no "reload a pack" call, so the host is reached through the
// adapter Noctis hands us (its `_owner` field is the PluginHost) and its public
// `Plugins` list and `LoadFrom(directory)` method. If a Noctis update renames those,
// the plugin logs what it could not find and does nothing else; the pack still
// applies at the next Noctis start.
//
// First run: rice.sh drops `select-once.txt` into the pack when it creates it, and
// this plugin then picks the Rice theme in Settings for you (and deletes the marker),
// so switching to another Noctis theme later is respected. While Rice *is* the active
// theme, every reload re-selects it, because that is the only path on which Noctis
// takes the accent from the theme (a plain re-read keeps the old accent).
using System.Collections;
using System.Reflection;
using System.Windows.Input;
using Noctis.Plugins;

namespace Rice.NoctisReloader;

public sealed class RiceReloaderPlugin : INoctisPlugin
{
    private const string PackId = "rice.theme";
    private const string ThemeKey = "rice.theme/rice";
    private const string Marker = "select-once.txt";
    private const BindingFlags Any = BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;

    private IPluginHost? _host;
    private SynchronizationContext? _ui;
    private FileSystemWatcher? _watcher;
    private Timer? _debounce;
    private string _packDir = "";

    public PluginInfo Info { get; } = new("rice.reloader", "Rice theme reloader", "1.0.0", "rice",
        "Re-reads the Rice colour pack whenever the desktop rice re-themes it, so Noctis follows `theme <name>` live.");

    public void Initialize(IPluginHost host)
    {
        _host = host;
        _ui = SynchronizationContext.Current; // Initialize runs on the UI thread; so must the host calls
        var pluginsDir = Path.GetDirectoryName(host.PluginDirectory.TrimEnd(Path.DirectorySeparatorChar)) ?? "";
        _packDir = Path.Combine(pluginsDir, PackId);

        _debounce = new Timer(_ => Post(Reload), null, Timeout.Infinite, Timeout.Infinite);
        _watcher = new FileSystemWatcher(pluginsDir)
        {
            IncludeSubdirectories = true,
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.Size,
        };
        _watcher.Changed += OnFileEvent;
        _watcher.Created += OnFileEvent;
        _watcher.Deleted += OnFileEvent;
        _watcher.Renamed += OnFileEvent;
        _watcher.EnableRaisingEvents = true;
        host.Log($"watching {_packDir}");

        // Pack installed while Noctis was closed: the marker is still there, select once startup settles.
        if (File.Exists(Path.Combine(_packDir, Marker)))
            _ = new Timer(_ => Post(SelectTheme), null, 2000, Timeout.Infinite);
    }

    public void Shutdown()
    {
        _watcher?.Dispose(); _watcher = null;
        _debounce?.Dispose(); _debounce = null;
    }

    private void OnFileEvent(object sender, FileSystemEventArgs e)
    {
        var hit = Under(e.FullPath) || (e is RenamedEventArgs r && Under(r.OldFullPath));
        if (hit) _debounce?.Change(500, Timeout.Infinite); // rice.sh writes two files; one reload
    }

    private bool Under(string path) =>
        string.Equals(path, _packDir, StringComparison.OrdinalIgnoreCase) ||
        path.StartsWith(_packDir + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase);

    private void Post(Action action)
    {
        void Guarded() { try { action(); } catch (Exception ex) { Log("failed: " + ex.GetBaseException().Message); } }
        if (_ui is not null) _ui.Post(_ => Guarded(), null); else Guarded();
    }

    private void Reload()
    {
        if (PluginHost() is not { } owner) { Log("plugin host not reachable (Noctis internals changed); the pack applies at next start"); return; }
        if (owner.GetType().GetProperty("Plugins", Any)?.GetValue(owner) is not IList plugins) { Log("Plugins list not found"); return; }

        object? existing = null;
        foreach (var p in plugins)
            if (string.Equals(p.GetType().GetProperty("Id", Any)?.GetValue(p) as string, PackId, StringComparison.OrdinalIgnoreCase)) { existing = p; break; }
        if (existing is not null) plugins.Remove(existing); // what InstallPackage does before re-reading a pack

        if (File.Exists(Path.Combine(_packDir, "plugin.json")))
        {
            var loadFrom = owner.GetType().GetMethod("LoadFrom", Any, new[] { typeof(string) });
            if (loadFrom is null) { Log("LoadFrom not found"); return; }
            loadFrom.Invoke(owner, new object[] { _packDir }); // Discover + Activate + publish content -> theme recolours
            Log("re-read the Rice pack");
            // Noctis seeds the accent from a pack theme only when the theme is *selected*, not
            // when its colours are re-read. So while Rice is the active theme, select it again:
            // same theme, but the accent picker follows the new palette too.
            if (File.Exists(Path.Combine(_packDir, Marker)) || IsRiceActive()) SelectTheme();
        }
        else if (existing is not null)
        {
            owner.GetType().GetMethod("RebuildContent", Any, Type.EmptyTypes)?.Invoke(owner, null); // pack gone: Settings falls back to the default theme
            Log("Rice pack removed");
        }
    }

    /// <summary>Settings > Appearance > Themes > Rice, done once for the user; then the marker goes.</summary>
    private void SelectTheme()
    {
        var marker = Path.Combine(_packDir, Marker);
        try { File.Delete(marker); } catch (IOException) { } catch (UnauthorizedAccessException) { }
        if (SettingsViewModel() is not { } settings) { Log("Settings not reachable; pick 'Rice' under Settings > Appearance > Themes"); return; }
        if (settings.GetType().GetProperty("ApplyPackThemeCommand", Any)?.GetValue(settings) is not ICommand apply) { Log("ApplyPackThemeCommand not found; pick 'Rice' under Settings > Appearance > Themes"); return; }
        apply.Execute(ThemeKey);
        Log("selected the Rice theme (accent " + ThemeKey + ")");
    }

    private static bool IsRiceActive() =>
        SettingsViewModel() is { } settings &&
        string.Equals(settings.GetType().GetProperty("ActivePackThemeKey", Any)?.GetValue(settings) as string, ThemeKey, StringComparison.OrdinalIgnoreCase);

    private object? PluginHost() => _host?.GetType().GetField("_owner", Any)?.GetValue(_host);

    private static object? SettingsViewModel()
    {
        var noctis = AppDomain.CurrentDomain.GetAssemblies().FirstOrDefault(a => a.GetName().Name == "Noctis");
        var services = noctis?.GetType("Noctis.App")?.GetProperty("Services", Any)?.GetValue(null) as IServiceProvider;
        var mainType = noctis?.GetType("Noctis.ViewModels.MainWindowViewModel");
        var main = mainType is null ? null : services?.GetService(mainType);
        return main?.GetType().GetProperty("Settings", Any)?.GetValue(main);
    }

    private void Log(string message) => _host?.Log(message);
}
