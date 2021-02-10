

plugins {
    id("com.palantir.docker")
//    id("com.palantir.docker-run")
}

/**
 * https://github.com/palantir/gradle-docker
 */
docker {
    name = "janusgraph/janusgraph:0.5.3"

    /**
     * Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
     * https://docs.docker.com/engine/reference/commandline/tag/
     */
    tag("vu-metalab-docker", "nexus.isis.vanderbilt.edu:29000/janusgraph:0.5.3")

    setDockerfile(file("${projectDir}/src/Dockerfile-openjdk8"))
    buildArgs(mapOf(
        "JANUS_VERSION" to "0.5.3",
        "JANUS_MAJOR_MINOR_VERSION" to "0.5"))

    labels(mapOf("description" to "This differs from the base image in that it can serialize TinkerGraph objects"))
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
