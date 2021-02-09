

pluginManagement {
    val palantirVersion = "0.26.0"
    plugins {
        id("com.palantir.docker").version(palantirVersion)
        id("com.palantir.docker-run").version(palantirVersion)
    }
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

//include("0.5")

