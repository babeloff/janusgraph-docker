

plugins {
    id("com.palantir.docker")
//    id("com.palantir.docker-run")
}

val janusMMVersion: String by project
val janusVersion: String by project

/**
 * https://github.com/palantir/gradle-docker
 */
docker {
    name = "janusgraph/janusgraph:${janusVersion}"

    /**
     * Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
     * https://docs.docker.com/engine/reference/commandline/tag/
     */
    tag("metalab", "nexus.isis.vanderbilt.edu:29000/janusgraph:2021.2.11")
    tag("latest", "janusgraph/janusgraph:latest")

    setDockerfile(file("${projectDir}/src/Dockerfile-openjdk8"))
    buildArgs(mapOf(
        "JANUS_VERSION" to janusVersion,
        "JANUS_MAJOR_MINOR_VERSION" to janusMMVersion
    ))

    labels(mapOf(
        "description" to "This differs from the base image in that it can serialize TinkerGraph objects"
    ))
    files(
        "src/docker-entrypoint.sh",
        "src/load-initdb.sh")
    copySpec.from("src/template")
    pull(false)
    noCache(false)
}

/**
 * To add a new task examine the following for the relevant information.
 *
 * https://api.github.com/repos/janusgraph/janusgraph/tags
 */
tasks {
}
