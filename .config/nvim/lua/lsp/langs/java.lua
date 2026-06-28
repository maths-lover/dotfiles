-- lua/lsp/langs/java.lua - Java (jdtls + google-java-format). JDK via brew "openjdk".
return {
  servers = {
    jdtls = {},
  },
  tools = { "google-java-format" },
}
