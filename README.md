# NetBench

CloudInfra initiative to monitor the network quality to reach the SWF services hosted in AWS Frankfurt region.

## Prerequisites

You need to have **docker** & **docker-compose** installed on the machine where you want to run the benchmark.

### Ubuntu

```bash
sudo apt -y update && sudo apt -y install docker docker-compose
```

### Windows

The easiest way to have **docker** & **docker-compose** available on Windows is installing [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Usage

### Ubuntu

- Clone the repository

```bash
git clone ssh://git@git.swf.daimler.com:7999/swfinternal/terraform/cloud-infra/netbench.git && cd netbench
```

- Duplicate the `.env.origin` file to `.env`
- Edit `.env` with your personal informations received by email

- **Option 1** : Run the test against  the SWF **internet** entrypoint
- - Edit `docker-compose-internet.yml` to specify where to find your SWF client certificates

    ```yaml
    ...
    volumes:
        - <path/to/swf.crt>:/swf.crt:ro
        - <path/to/swf.key>:/swf.key:ro
    ...
    ```
- - Run

    ```bash
    docker-compose -f docker-compose-internet.yml up --build
    ```

- **Option 2** : Run the test against  the SWF **intranet** entrypoint
- - Run

    ```bash
    docker-compose -f docker-compose-intranet.yml up --build
    ```

## Terminate the test

- Run

    ```bash
    docker-compose -f docker-compose-intranet.yml stop
    ```

    or
    ```bash
    docker-compose -f docker-compose-internet.yml stop
    ```

## Update to the latest version 

- Update the repo 

    ```bash
    git pull
    ```

- Rebuild & run

    ```bash
    docker-compose -f docker-compose-intranet.yml up --build --force-recreate
    ```

    or 

    ```bash
    docker-compose -f docker-compose-internet.yml up --build --force-recreate
    ```
