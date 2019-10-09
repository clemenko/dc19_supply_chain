# Building a Secure, Automated Supply Chain - Dockercon 2019

## Who am i

* Github : [https://github.com/clemenko](https://github.com/clemenko)
* Twitter : [@clemenko](https://twitter.com/clemenko)
* Email : [clemenko@docker.com](mailto:clemenko@docker.com)

---

In this lab you will integrate Docker Enterprise in to your development pipeline. You will push an image to the Docker Trusted Registry (DTR). DTR will scan your image for vulnerabilities so they can be fixed before your application is deployed. This helps you build more secure apps!

> **Difficulty**: Intermediate
>
> **Time**: Approximately 90 minutes
>
> **Tasks**:
>
> * [Who am i](#who-am-i)
> * [Document conventions](#document-conventions)
> * [Abbreviations](#abbreviations)
> * [Prerequisites](#prerequisites)
> * [Understanding the Play With Docker Interface](#understanding-the-play-with-docker-interface)
>   * [1. Console Access](#1-console-access)
>   * [2. Access to your Universal Control Plane (UCP) and Docker Trusted Registry (DTR) servers](#2-access-to-your-universal-control-plane-ucp-and-docker-trusted-registry-dtr-servers)
>   * [3. Session Information](#3-session-information)
> * [Introduction](#introduction)
> * [Task 1 Accessing PWD](#task-1---accessing-pwd)
>   * [Task 1.1 Set Up Environment Variables](#task-11---set-up-environment-variables)
> * [Task 2 Enable Docker Image Scanning](#task-2---enable-docker-image-scanning)
> * [Task 3 Create Jenkins User and Organization](#task-3---create-jenkins-user-and-organization)
>   * [Task 3.1 Create Jenkins Organization](#task-31---create-jenkins-organization)
>   * [Task 3.2 Create Jenkins User](#task-32---create-jenkins-user)
>   * [Task 3.3 Create Jenkins DTR Token](#task-33--create-jenkins-dtr-token)
> * [Task 4: Create DTR Repositories](#task-4---create-dtr-repositories)
>   * [Task 4.1 Create Promotion Policy - Private to Public](#task-41---create-promotion-policy---private-to-public)
> * [Task 5 Pull / Tag / Push Docker Image](#task-5---pull--tag--push-docker-image)
> * [Task 6 Review Scan Results](#task-6---review-scan-results)
>   * [Task 6.1 Hide Vulnerabilities](#task-61---hide-vulnerabilities)
> * [Task 7 Extend with Image Mirroring](#task-7---extend-with-image-mirroring)
> * [Task 8 Docker Content Trust / Image Signing](#task-8---docker-content-trust--image-signing)
> * [Task 9 Automate with Jenkins](#task-9---automate-with-jenkins)
>   * [Task 9.1 Deploy Jenkins](#task-91---deploy-jenkins)
>   * [Task 9.2 Plumb Jenkins](#task-92---plumb-jenkins)
>   * [Task 9.3 Webhooks](#task-93---webhooks)
> * [Conclusion](#conclusion)

## Document conventions

When you encounter a phrase in between `<` and `>`  you are meant to substitute in a different value.
We are going to leverage the power of [Play With Docker](http://play-with-docker.com).

## Abbreviations

The following abbreviations are used in this document:

* UCP = Universal Control Plane
* DTR = Docker Trusted Registry
* DCT = Docker Content Trust
* CVE = Common Vulnerabilities and Exposures
* PWD = Play With Docker

## Prerequisites

This lab requires an instance of Docker Enterprise. Docker Enterprise includes Docker Universal Control Plane and Docker Trusted Registry. This lab provides Docker Enterprise.

## Understanding the Play With Docker Interface

![pwd screen](./img/pwd_screen.jpg)

This workshop is only available to people in a pre-arranged workshop. That may happen through a [Docker Meetup](https://events.docker.com/chapters/), a conference workshop that is being led by someone who has made these arrangements, or special arrangements between Docker and your company. The workshop leader will provide you with the URL to a workshop environment that includes [Docker Enterprise](https://www.docker.com/enterprise-edition). The environment will be based on [Play with Docker](https://labs.play-with-docker.com/).

If none of these apply to you, contact your local [Docker Meetup Chapter](https://events.docker.com/chapters/) and ask if there are any scheduled workshops. In the meantime, you may be interested in the labs available through the [Play with Docker Classroom](https://training.play-with-docker.com/alacart/).

There are three main components to the Play With Docker (PWD) interface.

### 1. Console Access

Play with Docker provides access to the 3 Docker Enterprise hosts in your Cluster. These machines are:

* A Linux-based Docker Enterprise 2.1 (UCP 3.1.6 & DTR 2.6.5 & 18.09.2)  Manager node
* Three Linux-based Docker Enterprise 2.1 (18.09.2) Worker nodes

By clicking a name on the left, the console window will be connected to that node.

### 2. Access to your Universal Control Plane (UCP) and Docker Trusted Registry (DTR) servers

Additionally, the PWD screen provides you with a one-click access to the Universal Control Plane (UCP)
web-based management interface as well as the Docker Trusted Registry (DTR) web-based management interface. Clicking on either the `UCP` or `DTR` button will bring up the respective server web interface in a new tab.

### 3. Session Information

Throughout the lab you will be asked to provide either hostnames or login credentials that are unique to your environment. These are displayed for you at the bottom of the screen.

**Note:**  There are a limited number of lab connections available for the day. You can use the same session all day by simply keeping your browser connection to the PWD environment open between sessions. This will help us get as many people connected as possible, and prevent you needing to get new credentials and hostnames in every lab. However, if you do lose your connection between sessions simply go to the PWD URL again and you will be given a new session.

## Introduction

This workshop is designed to demonstrate the power of Docker Secrets, Image Promotion, Scanning Engine, and Content Trust. We will walk through creating a few secrets. Deploying a stack that uses the secret. Then we will create a Docker Trusted Registry repository where we can create a promotion policy. The promotion policy leverages the output from Image Scanning result. This is the foundation of creating a Secure Supply Chain. You can read more about  secure supply chains for our [Secure Supply Chain reference architecture](https://success.docker.com/article/secure-supply-chain).

## Task 1 - Accessing PWD

1. Navigate in your web browser to the URL the workshop organizer provided to you. **Chrome is advised!**

2. Fill out the form, and click `submit`. You will then be redirected to the PWD environment. It may take a minute or so to provision out your PWD environment.

### Task 1.1 - Set Up Environment Variables

We are going to use `worker3` for **ALL** our command line work. Click on `worker3` to activate the shell.

![pwd screen](img/pwd_screen.jpg)

Now we need to setup a few variables. We need to create `DTR_URL` and `DTR_USERNAME`. But the easiest way is to clone the Workshop Repo and run script.

```bash
git clone https://github.com/clemenko/dc19_supply_chain.git
```

Once cloned, now we can run the `var_setup.sh` script.

```bash
source dc19_supply_chain/scripts/var_setup.sh
```

Now your PWD environment variables are setup. We will use the variables for some scripting.

## Task 2 - Enable Docker Image Scanning

Before we create the repositories, let's start with enabling the Docker Image Scanning engine.

1. From the main PWD screen click the `DTR` button on the left side of the screen

    > **Note**: Because this is a lab-based install of Docker Enterprise we are using the default self-signed certs. Because of this your browser may display a security warning. It is safe to click through this warning.
    >
    > In a production environment you would use certs from a trusted certificate authority and would not see this screen.
    >
    > ![ssl_error](./img/ssl_error.png)

2. Navigate to `System` on the left pane, then `Security`.
    ![scanning](img/system_scanning.jpg)

3. Select `Enable Scanning`. Leave it in `Online` mode and select `Enable`. Press the button `Enable Online Scanning`. The CVE database will start downloading. This can take a few minutes. Please be patient for it to complete.
    ![enable_scan](img/scanning_enable.jpg)

## Task 3 - Create Jenkins User and Organization

In order to setup our automation we need to create an organization and a user account for Jenkins. We are going to create a user named `jenkins` in the organization `ci`.

### Task 3.1 - Create Jenkins Organization

1. From the `PWD` main page click on `DTR`.
  ![orgs](img/orgs_1.jpg)

2. Once in `DTR` navigate to `Organizations` on the left.
3. Now click `New organization`.
4. Type in `ci` and click `Save`.
  ![new_org](img/new_org.jpg)

Now we should see the organization named `ci`.

![new_org2](img/orgs_2.jpg)

### Task 3.2 - Create Jenkins User

While remaining in DTR we can create the user from here.

1. Click on the organization `ci`.
2. Click `Add user`.
3. Make sure you click the radio button `New`. Add a new user name `jenkins`. Set a simple password that you can remember. Maybe `admin1234`?

    ![newuser](img/new_user.jpg)

Now change the permissions for the `jenkins` account to `Org Owner`.

![admin](img/org_admin.jpg)

### Task 3.3 - Create Jenkins DTR Token

Now that we have the `jenkins` user created we need to add a token for use with DTR's API.

Navigate to `Users` on the left pane. Click on `jenkins`, then click the `Access Tokens` tab.

![token](img/token.jpg)

Click `New access token`. Enter `Supply Chain` into the description field and click `Create`.

**Write down the token that is displayed. You will need this again!**

It should look like `ee9d7ff2-6fd4-4a41-9971-789e06e0d5d5`. Click `Done`.

Lets add it to the `worker3` environment. Replace `<TOKEN>` with the token from DTR.

```bash
#example
#export DTR_TOKEN=ee9d7ff2-6fd4-4a41-9971-789e06e0d5d5
export DTR_TOKEN=<TOKEN>
```

## Task 4 - Create DTR Repositories

We now need to access Docker Trusted Registry to setup two repositories.

We have an easy way with a script or the hard way by using the GUI.

Either way we need to create two repositories, `dc19_build` and `dc19`. `dc19_build` will be used for the private version of the image. `dc19` will be the public version once an CVE scan is complete.

**Easy Way:**

Since we used `git clone` to copy the repository to `worker3` for this workshop, there is a script from that will create the DTR repositories.

```bash
./dc19_supply_chain/scripts/create_repos.sh
```

Feel free to `cat` the file to see how we are using `curl` and the API to create the repositories.

```bash
[worker3] (local) root@10.20.0.38 ~
$ cat dc19_supply_chain/scripts/create_repos.sh
#!/bin/bash
# requires environment variables: DTR_HOST, DTR_USERNAME and DTR_TOKEN

if [ -z "$DTR_TOKEN" ]; then
  echo " Please create a DTR_TOKEN variable before preceding..."
  exit
fi

curl -X POST -k -L \
  -u $DTR_USERNAME:$DTR_TOKEN \
  https://$DTR_URL/api/v0/repositories/ci \
  -H 'Content-Type: application/json' \
  -d '{
  "enableManifestLists": true,
  "immutableTags": true,
  "longDescription": "",
  "name": "dc19",
  "scanOnPush": true,
  "shortDescription": "Dockercon 2019 Example - public",
  "visibility": "public"
}'

curl -X POST -k -L \
  -u $DTR_USERNAME:$DTR_TOKEN \
  https://$DTR_URL/api/v0/repositories/ci \
  -H 'Content-Type: application/json' \
  -d '{
  "enableManifestLists": true,
  "immutableTags": true,
  "longDescription": "",
  "name": "dc19_build",
  "scanOnPush": true,
  "shortDescription": "Dockercon 2019 Example - private",
  "visibility": "public"
}'
```

**Hard Way:**

1. Navigate to `Repositories` on the left menu and click `New repository`.
2. Create that looks like `ci`/`dc19_build`. Make sure you click `Private`. Do not click `Create` yet!
3. Click `Show advanced settings` and then click `On Push` under `SCAN ON PUSH`.  This will ensure that the CVE scan will start right after every push to this repository.  And turn on `IMMUTABILITY`. Then click `Create`.
  ![new_repo](img/new_repo.jpg)

4. Repeat this for creating the `ci`/`dc19` `Public` repository with `SCAN ON PUSH` set to `On Push` and `IMMUTABILITY` turned `Off`.

5. We should have two repositories now.
  ![new_repo](img/repo_list.jpg)

### Task 4.1 - Create Promotion Policy - Private to Public

With the two repositories setup we can now define the promotion policy. The first policy we are going to create is for promoting an image that has passed a scan with zero (0) **Critical** vulnerabilities. The policy will target the `ci`/`dc19` repository.

1. Navigate to the `ci`/`dc19_build` repository. Click `Promotions` and click `New promotion policy`. Note: Make sure the `Is source` box is
selected.
  ![create](img/create_policy.jpg)

2. In the `PROMOTE TO TARGET IF...` box select `Critical Vulnerabilities` and then check `less than or equals`. In the box below `equals` enter the number zero (4) and click `Add`.
3. Set the `TARGET REPOSITORY` to `ci`/`dc19` and click `Save & Apply`.
  ![promo](img/promo_policy.jpg)

When we push an image to `ci`/`dc19_build` it will get scanned. Based on that scan report we could see the image moved to `ci`/`dc19`. Lets push a few images to see if it worked.

## Task 5 - Pull / Tag / Push Docker Image

Lets pull, tag, and push a few images to YOUR DTR.

In order to push and pull images to DTR we will need to take advantage of PWD's Console Access.

1. Navigate back to the PWD tab in your browser.
2. Click on `worker3`.
3. In the console we should already have a variable called `DTR_URL`. Lets check.

    ```bash
    echo $DTR_URL
    ```

    If you are not sure please follow [Task 1.1 Set Up Environment Variables](#task-11---set-up-environment-variables).

4. Now we login to our DTR server using your `DTR_TOKEN` from [Task 3.3 Create Jenkins DTR Token](#task-33---create-jenkins-dtr-token).

    ```bash
    docker login -u jenkins -p $DTR_TOKEN $DTR_URL
    ```

5. Now we can start pulling a few images.

    ```bash
    docker pull clemenko/dc19:0.1
    docker pull clemenko/dc19:0.2
    docker pull clemenko/dc19:0.3
    docker pull alpine
    ```

    This command is pull a few images from [hub.docker.com](https://hub.docker.com).

6. Now let's tag the image for our DTR instance. We will use the `URL` variable we set before.

    ```bash
    docker tag clemenko/dc19:0.1 $DTR_URL/ci/dc19_build:0.1
    docker tag clemenko/dc19:0.2 $DTR_URL/ci/dc19_build:0.2
    docker tag clemenko/dc19:0.3 $DTR_URL/ci/dc19_build:0.3
    docker tag alpine $DTR_URL/ci/dc19_build:alpine
    ```

7. Now we can `docker push` the images to DTR.

    ```bash
    docker push $DTR_URL/ci/dc19_build:0.1
    docker push $DTR_URL/ci/dc19_build:0.2
    docker push $DTR_URL/ci/dc19_build:0.3
    docker push $DTR_URL/ci/dc19_build:alpine
    ```

## Task 6 - Review Scan Results

Lets take a good look at the scan results from the images. Please keep in mind this will take a few minutes to complete.

1. Navigate to DTR --> `Repositories` --> `ci/dc19_build` --> `Tags`.

    Don't worry if you see images in a `Scanning...` or `Pending` state. Please click to another tab and click back.

    ![list](img/image_list.jpg)

2. Take a look at the details to see exactly what piece of the image is vulnerable.

     Click `View details` for an image that has vulnerabilities. How about `0.2`? There are two views for the scanning results, **Layers** and **Components**. The **Layers** view shows which layer of the image had the vulnerable binary. This is extremely useful when diagnosing where the vulnerability is in the Dockerfile.

     ![list](img/image_view.jpg)

    The vulnerable binary is displayed, along with all the other contents of the layer, when you click the layer itself. In this example there are a few potentially vulnerable binaries:

    ![list](img/image_comp.jpg)

    Now we have a chance to review each vulnerability by clicking the CVE itself, example `CVE-2019-3822`. This will direct you to Mitre's site for CVEs.

    ![list](img/mitre.jpg)

    Now that we know what is in the image. We should probably act upon it.

### Task 6.1 - Hide Vulnerabilities

If we find that they CVE is a false positive. Meaning that it might be disputed, or from OS that you are not using. If this is the case we can simply `Hide` the vulnerability. This will not remove the fact that the CVE was found.

Click `Show layers affected` and then you can click `Hide` for the one critical CVE.

![hide](img/cve_hide.jpg)

If we click back to `Tags` we can now see that the image does not have a critical vulnerability.

![critical](img/cve_no_critical.jpg)

Once we have hidden some CVEs we might want to perform a manual promotion of the image.

## Task 7 - Extend with Image Mirroring

Docker Trusted Registry allows you to create mirroring policies for a repository. When an image gets pushed to a repository and meets a certain criteria, DTR automatically pushes it to repository in another DTR deployment or Docker Hub.

This not only allows you to mirror images but also allows you to create image promotion pipelines that span multiple DTR deployments and datacenters. Let's set one up. How about we mirror an image to [hub.docker.com](https://hub.docker.com)?

1. Go to [hub.docker.com](https://hub.docker.com) and create an login and repository.

2. Navigate to `Repositories` --> `ci`/`dc19` --> `MIRRORS` --> `New mirror`.
   Change the `REGISTRY TYPE` to `Docker Hub` and fill out the relevant information like:

   ![mirror1](img/mirror.jpg)

3. Click `Connect` and scroll down.
4. Next create a `tag name` Trigger that is equal to `promoted`
5. Leave the `%n` tag renaming the same.
6. Click `Save & Apply`.
    ![mirror2](img/mirror2.jpg)

Since we already had an image that had the tag `promoted` we should see that the image was pushed to [hub.docker.com](https://hub.docker.com). In fact we can click on the [hub](https://hub.docker.com) repository name to see if the image push was successful.

![more](img/mirror3.jpg)

## Task 8 - Docker Content Trust / Image Signing

Docker Content Trust/Notary provides a cryptographic signature for each image. The signature provides security so that the image requested is the image you get. Read [Notary's Architecture](https://docs.docker.com/notary/service_architecture/) to learn more about how Notary is secure. Since Docker Enterprise is "Secure by Default," Docker Trusted Registry comes with the Notary server out of the box.

We can create policy enforcement within Universal Control Plane (UCP) such that **ONLY** signed images from the `ci` team will be allowed to run. Since this workshop is about DTR and Secure Supply Chain we will skip that step.

Let's sign your first Docker image?

1. Right now you should have a promoted image `$DTR_URL/ci/dc19:0.2`. We need to tag it with a new `signed` tag.

   ```bash
   docker pull $DTR_URL/ci/dc19:0.2
   docker tag $DTR_URL/ci/dc19:0.2 $DTR_URL/ci/dc19:signed
   ```

2. Now lets use the Trust command... It will ask you for a BUNCH of passwords. Do yourself a favor in this workshop and use `admin1234`. :D

    ```bash
    docker trust sign $DTR_URL/ci/dc19:signed
    ```

    Here is an example output:

    ```bash
    [worker3] (local) root@10.20.0.42 ~
    $ docker trust sign $DTR_URL/ci/dc19:signed
    You are about to create a new root signing key passphrase. This passphrase
    will be used to protect the most sensitive key in your signing system. Please
    choose a long, complex passphrase and be careful to keep the password and the
    key file itself secure and backed up. It is highly recommended that you use a
    password manager to generate the passphrase and keep it safe. There will be no
    way to recover this key. You can find the key in your config directory.
    Enter passphrase for new root key with ID b975982:
    Repeat passphrase for new root key with ID b975982:
    Enter passphrase for new repository key with ID 61a14ae:
    Repeat passphrase for new repository key with ID 61a14ae:
    Enter passphrase for new jenkins key with ID ab5049d:
    Repeat passphrase for new jenkins key with ID ab5049d:
    Created signer: jenkins
    Finished initializing signed repository for ip172-18-0-5-bfu00sinjdg00099igu0.direct.ee-beta2.play-with-docker.com/ci/dc19:signed
    Signing and pushing trust data for local image ip172-18-0-5-bfu00sinjdg00099igu0.direct.ee-beta2.play-with-docker.com/ci/dc19:signed, may overwrite remote trust data
    The push refers to repository [ip172-18-0-5-bfu00sinjdg00099igu0.direct.ee-beta2.play-with-docker.com/ci/dc19]
    af9af2170d23: Layer already exists
    cd9a82baa926: Layer already exists
    c60ea83f6a45: Layer already exists
    cd7100a72410: Layer already exists
    signed: digest: sha256:5554013b565fc0ccf080f7cf4ad096ffb1dbc4f83496a86f9efa1252f26ed455 size: 1156
    Signing and pushing trust metadata
    Enter passphrase for jenkins key with ID ab5049d:
    Successfully signed ip172-18-0-5-bfu00sinjdg00099igu0.direct.ee-beta2.play-with-docker.com/ci/dc19:signed
    [worker3] (local) root@10.20.0.42 ~
    ```

    Again please use the same password. It will simplify this part of the workshop.

3. And we can confirm the signature has been applied by inspecting the image:

    ```bash
    docker trust inspect $DTR_URL/ci/dc19:signed
    ```

    Here is the example output:

      ```bash
      [worker3] (local) root@10.20.0.42 ~
      $ docker trust inspect $DTR_URL/ci/dc19:signed
      [
        {
            "Name": "ip172-18-0-5-bfu00sinjdg00099igu0.direct.ee-beta2.play-with-docker.com/ci/dc19:signed",
            "SignedTags": [
                {
                    "SignedTag": "signed",
                    "Digest": "5554013b565fc0ccf080f7cf4ad096ffb1dbc4f83496a86f9efa1252f26ed455",
                    "Signers": [
                        "jenkins"
                    ]
                }
            ],
            "Signers": [
                {
                    "Name": "jenkins",
                    "Keys": [
                        {
                            "ID": "ab5049def46b1b8070891981afe6091f95bf9017cdfc447866917f342810a302"
                        }
                    ]
                }
            ],
            "AdministrativeKeys": [
                {
                    "Name": "Root",
                    "Keys": [
                        {
                            "ID": "59eaa1440dfc9fbf709a9640e8b8fbcb636b019f6f70aa90451f361bbd1ecf58"
                        }
                    ]
                },
                {
                    "Name": "Repository",
                    "Keys": [
                        {
                            "ID": "61a14ae35425dde74dc5d18b292c613f613b357051862c18ca5d0a02a2f0d04e"
                        }
                    ]
                }
            ]
        }
      ]
      [worker3] (local) root@10.20.0.42 ~
      ```

4. Back in DTR, Navigate to `Repositories` --> `ci`/`dc19` --> `Tags` and you will now see the new `signed` tag with the text `Signed` under the `Signed` column:

    ![promoted](img/promoted_signed.jpg)

5. If you were to enable Docker Content Trust in UCP then you would need to upload the public certificate used to sign the image. As we did not perform the `docker trust signer add` command before step 2 above then a public certificate is automatically generated but is not associated to a user in UCP. This means when UCP tries to verify the signature on a signed image to a user it will fail and therefor not meet UCP's Content Trust policy.

    To resolve this issue you can upload the base64 encoded public certificate in `~/.docker/trust/tuf/$DTR_URL/ci/dc19/metadata/targets.json` - the certificate is located in the structure `.signed.delegations.keys` with the key value of `public`.

    For example, use the command `cat ~/.docker/trust/tuf/$DTR_URL/ci/dc19/metadata/targets.json | jq '.signed.delegations.keys' | grep public` to extract the certificate.

## Task 9 - Automate with Jenkins

In order to automate we need to deploy Jenkins. If you want I can point you to a few Docker Compose yamls. OR we have the easy way. The easy, aka script, deploys Jenkins quickly.

### Task 9.1 - Deploy Jenkins

1. Take a look at the script. Also notice the script will check variables, and then runs `docker run`.

    ```bash
    cat ./dc19_supply_chain/scripts/jenkins.sh
    ```

2. Then run unset Docker Content Trust and instal Jenkins.

    ```bash
    ./dc19_supply_chain/scripts/jenkins.sh
    ```

3. Pay attention to the url AND Jenkins password. It will look like :

    ```bash
    [worker3] (local) root@10.20.0.25 ~/
    $ dc19_supply_chain/scripts/jenkins.sh
    =========================================================================================================

      Jenkins URL : http://ip172-18-0-20-bcelih5dffhg00b2thog.direct.ee-beta2.play-with-docker.com:8080

    =========================================================================================================
      Waiting for Jenkins to start................
    =========================================================================================================

      Jenkins Setup Password = d32eda1cf2464b818826fd82b4f7c2cb

    =========================================================================================================
    ```

4. Now navigate to `http://$DOCS_URL:8080` by clicking on the url in the terminal. Let's start the setup of Jenkins and enter the password. It may take a minute or two for the `Unlock Jenkins` page to load. Be patient.
  ![token](img/jenkins_token.jpg)

5. Click `Select plugins to install`.
  ![plugins](img/jenkins_plugins1.jpg)

6. We don't need to install all plugins at this point. Click `none` at the top.
  ![none](img/jenkins_none.jpg)

7. Next Click `Continue as admin` in the lower right hand corner. We don't need to create another username for Jenkins.
  ![continue](img/jenkins_continue.jpg)

8. Next for Instance Configuration click `Save and Finish`.
  ![instance](img/jenkins_instance.jpg)

9. And we are done installing Jenkins. Click `Start using Jenkins`
  ![finish](img/jenkins_finish.jpg)

### Task 9.2 - Plumb Jenkins

Now that we have Jenkins setup and running we need to add 3 additional plugins - Blue Ocean, Generic Webhook Trigger and Pipeline:

1. Click on `Manage Jenkins` --> `Manage Plugins` --> `Available` and filter/search for `Blue Ocean`, `Generic Webhook Trigger` and `Pipeline`. When you have found each one check the checkbox to the left of the plugin name to select for installation.

2. Click on `Install without restart` and wait for the plugins to install. When all plugins have installed navigate back to the Jenkins homepage.

3. Click on `New item` in the upper left.
  ![newitem](img/jenkins_newitem.jpg)

4. Enter a name like `ci_dc19`, click `Freestyle project` and then click `OK`.
  ![time](img/jenkins_item.jpg)

5. Let's scroll down to the `Build` section. We will come back to the `Build Triggers` section in a bit. Now click `Add build step` --> `Execute shell`.
  ![build](img/jenkins_build.jpg)

6. You will now see a text box. Past the following build script into the text box.

    **Please replace the <DTR_URL> with your URL! `echo $DTR_URL` <-- `worker3`**

    ```bash
    DTR_USERNAME=admin
    DTR_URL=<DTR_URL>

    docker login -u admin -p admin1234 $DTR_URL

    docker pull clemenko/dc19:0.2

    docker tag clemenko/dc19:0.2 $DTR_URL/ci/dc19_build:jenkins_$BUILD_NUMBER

    docker push $DTR_URL/ci/dc19_build:jenkins_$BUILD_NUMBER

    docker rmi clemenko/dc19:0.2 $DTR_URL/ci/dc19_build:jenkins_$BUILD_NUMBER
    ```

    It will look very similar to:
    ![build2](img/jenkins_build2.jpg)

      Now scroll down and click `Save`.

7. Now let's run the build. Click `Build now`.
  ![now](img/jenkins_buildnow.jpg)

8. You can watch the output of the `Build` by clicking on the task number in the `Build History` and then selecting `Build Output`
  ![history](img/jenkins_bhistory.jpg)

9. The console output will show you all the details from the script execution.
  ![output](img/jenkins_output.jpg)

10. Review the `ci`/`dc19` repository in DTR. You should now see a bunch of tags that have been promoted.
  ![supply](img/automated_supply.jpg)

### Task 9.3 - Webhooks

Now that we have Jenkins setup we can extend with webhooks. In Jenkins speak a webhook is simply a build trigger. Let's configure one.

1. Navigate to Jenkins and click on the project/item called `ci_dc19` and click on `Configure` on the left hand side.
  ![configure](img/jenkins_configure.jpg)

2. Then scroll down to `Build Triggers`. Check the checkbox for `Trigger builds remotely` and enter a Token of `dc19_rocks`.  Scroll down and click `Save`.
  ![trigger](img/jenkins_triggers.jpg)

3. Now in your browser goto YOUR `http://$DOCS_URL:8080/job/ci_dc19/build?token=dc19_rocks`

    It should look like: `http://ip172-18-0-9-bis91vft0fgg00ctq3i0.direct.ee-beta2.play-with-docker.com:8080/job/ci_dc19/build?token=dc19_rocks`

4. Check DTR to verify the images were pushed. Then log into `https:hub.docker.com` to see if your images were mirrored.

    ![hub_mirror](img/hub_mirror.jpg)

## Conclusion

In this workshop we were able use the tools that are included with Docker Trusted Registry to build a basic Automated Secure Supply Chain. Hopefully with this foundation you can build your own organizations Secure Supply Chain!
