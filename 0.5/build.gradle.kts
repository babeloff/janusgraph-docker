
plugins {
    id("com.palantir.docker")
//    id("com.palantir.docker-run")
}

/**
 * https://github.com/palantir/gradle-docker
 */
docker {
    name = "hub.docker.com/phreed/janusgraph:0.5.3"

    tag("myRegistry", "docker.hub/janusgraph/janusgraph:0.5.3")
    setDockerfile(file("Dockerfile"))
    files("docker-entrypoint.sh",
        "load-initdb.sh")
    copySpec.from("src").into("")

//    buildArgs([BUILD_VERSION: 'version'])
//    labels(['key': 'value'])
//    pull true
//    noCache true

}

//dockerRun {
//    name 'my-container'
//    image 'busybox'
//    volumes 'hostvolume': '/containervolume'
//    ports '7080:5000'
//    daemonize true
//    env 'MYVAR1': 'MYVALUE1', 'MYVAR2': 'MYVALUE2'
//    command 'sleep', '100'
//    arguments '--hostname=custom', '-P'
//}

