# Maven settings encryption

**Since 2.1.0**

Maven allow server password encryption in the `settings.xml` file (see [Password encryption](https://maven.apache.org/guides/mini/guide-encryption.html)).
This is especially useful when the `settings.xml` file :
* Is shared between multiple users / environments (e.g. Stored in `VCS`)
* Contains credentials with different access rights
  * Read-Write (`RW`) credentials for artifact publishing
  * Read-Only (`RO`) credentials for artifact downloading

You can encrypt `RW` credentials and share the master encryption password with authorized users (or on selected deployment contexts).
You can leave the `RO` credentials unencrypted for everyone to use.

## Maven artifact registries

Different maven artifact registries implementation are used to test encryption capabilities.

* [GCP Artifact Registry](https://cloud.google.com/artifact-registry)
* [Gitlab package registry](https://docs.gitlab.com/ee/user/packages/package_registry/)
* [Sonatype nexus](https://www.sonatype.com/products/sonatype-nexus-repository)

ℹ️ **You don't have all to use all three repositories, they were mainly used for educational purposes. Moreover, some of those repositories (e.g. GCP artifact registry) provide alternative authentication method which do not require password usage (e.g. ADC). 
Then again, the section below is purely for educational purposes. You should follow provider best practices.** ℹ️

### GCP artifact registry

The instructions below are based on [GCP store java packages in artifact registry](https://cloud.google.com/artifact-registry/docs/java/store-java) and [Set up authentication for maven](https://cloud.google.com/artifact-registry/docs/java/authentication) documentation.

1. Create a GCP project and **optionally** under your organization

```shell
gcloud auth login --no-launch-browser && \
gcloud projects create maven-registry --organization=ORGANIZATION_ID && \
gcloud config set project maven-registry
```

1. Create a new Java package repository

```shell
gcloud artifacts repositories create breizhcamp2023-<randomSalt> --repository-format=maven --location=us-central1
```

2. Update the registry url via the property `gcp.maven.registry.uri` in [pom.xml](../pom.xml)

3. Create a service account `maven-cli` with `roles/artifactregistry.writer` role on your project

```shell
gcloud iam service-accounts create maven-cli --description="RW SA for maven CLI" --display-name="maven-cli" && \
gcloud projects add-iam-policy-binding PROJECT_ID --member="serviceAccount:maven-cli@maven-registry.iam.gserviceaccount.com" --role="roles/artifactregistry.writer" && \
gcloud iam service-accounts keys create ./gcp-artifact/src/main/resources/maven-cli.json --iam-account=maven-cli@maven-registry.iam.gserviceaccount.com
```

4. Create a service account `maven-cli-ro` with `roles/artifactregistry.reader` role on your project

```shell
gcloud iam service-accounts create maven-cli-ro --description="RO SA for maven CLI" --display-name="maven-cli-ro" && \
gcloud projects add-iam-policy-binding PROJECT_ID --member="serviceAccount:maven-cli-ro@maven-registry.iam.gserviceaccount.com" --role="roles/artifactregistry.reader" && \
gcloud iam service-accounts keys create ./gcp-artifact/src/main/resources/maven-cli-ro.json --iam-account=maven-cli-ro@maven-registry.iam.gserviceaccount.com
```

5. Generate the raw maven registry authentication information for `maven-cli` using `gcloud` and **save the content for later**

```shell
gcloud artifacts print-settings mvn \
    --project=maven-registry \
    --repository=breizhcamp2023-<randomSalt> \
    --location=us-central1 \
    --json-key=./gcp-artifact/src/main/resources/maven-cli.json
```

6. Generate the raw maven registry authentication information for `maven-cli-ro` using `gcloud`.

```shell
gcloud artifacts print-settings mvn \
    --project=maven-registry \
    --repository=breizhcamp2023-<randomSalt> \
    --location=us-central1 \
    --json-key=./gcp-artifact/src/main/resources/maven-cli-ro.json
```

7. You can update your `settings.xml` with `maven-cli-ro` information without encryption

### Gitlab artifact registry

The instructions below are based on [Publish to the Gitlab Package registry](https://docs.gitlab.com/ee/user/packages/maven_repository/#publish-to-the-gitlab-package-registry).

1. Generate a **read-write** [project deploy token](https://docs.gitlab.com/ee/user/project/deploy_tokens/) with the characteristics below and **save the token for later**

```
Username: bzhcamp
Scopes: read_package_registry, write_package_registry
```

2. Generate a **read-only** [project deploy token](https://docs.gitlab.com/ee/user/project/deploy_tokens/) with the characteristics

```
Username: bzhcamp-ro
Scopes: read_package_registry
```

3. You can update your `settings.xml` with section below

```xml
<server>
  <id>gitlab-maven-registry-ro</id>
  <configuration>
    <httpHeaders>
      <property>
        <name>Deploy-Token</name>
        <value>changeme:clear_text_read_only_token</value>
      </property>
    </httpHeaders>
  </configuration>
</server>
```

4. Update gitlab related properties in [pom.xml](../pom.xml)

### Nexus artifact registry

1. Create a `maven hosted` repository called `breizhcamp`
2. Create a custom role `bzhcamp-rw` with the privileges below

```
nx-repository-admin-maven2-breizhcamp-browse
nx-repository-admin-maven2-breizhcamp-read
nx-repository-view-maven2-breizhcamp-browse
nx-repository-view-maven2-breizhcamp-read
```

3. Create a technical user `bzhcamp` and assign it the `bzhcamp-rw` role created above. **Save the password for later**.
4. Create a custom role `bzhcamp-ro` with the privileges below

```
nx-repository-admin-maven2-breizhcamp-*
nx-repository-view-maven2-breizhcamp-*
```

5. Create a technical user `bzhcamp-ro` and assign it the `bzhcamp-ro` role created above. You can add the section below in your `settings.xml`

```xml
<server>
    <id>nexus-maven-registry-ro</id>
    <username>bzhcamp-ro</username>
    <password>changeme:clear_text_read_only_user_password</password>
</server>
```

6. Update nexus related properties in [pom.xml](../pom.xml)

## Generate the master encryption password

See [How to create a master password](https://maven.apache.org/guides/mini/guide-encryption.html#how-to-create-a-master-password)

1. Set the master encryption password

```shell
mvn --encrypt-master-password
```

2. Create the `${user.home}/.m2/settings-security.xml` file

```xml
<settingsSecurity>
  <master>changeme:output_from_previous_command</master>
</settingsSecurity>
```

## Encrypt the sensible information

### Encrypt GCP credentials

We'll encrypt the relevant part of the `gcloud artifacts print-settings mvn` command for `maven-cli` executed above

1. Copy the content of the `password` tag : it should be quite a long string
2. Encrypt the password using `mvn --encrypt-password`
3. Replace the content of the `password` tag with the encrypted one
4. Add the corresponding section into your `settings.xml`

```xml
<server>
    <id>gcp-artifact-registry</id>
    <configuration>
        <httpConfiguration>
            <get>
                <usePreemptive>true</usePreemptive>
            </get>
            <head>
                <usePreemptive>true</usePreemptive>
            </head>
            <put>
                <params>
                    <property>
                        <name>http.protocol.expect-continue</name>
                        <value>false</value>
                    </property>
                </params>
            </put>
        </httpConfiguration>
    </configuration>
    <username>_json_key_base64</username>
    <password>{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}</password>
</server>
```

⚠️ Make sure that you remove any _new line_ before encrypting your password⚠️

### Encrypt Gitlab credentials

We'll encrypt the `bzhcamp` deploy token.

1. Encrypt the token using `mvn --encrypt-password`
3. Replace the content of the `value` tag with the encrypted one
4. Add the corresponding section into your `settings.xml`

```xml
<server>
    <id>gitlab-maven-registry</id>
    <configuration>
        <httpHeaders>
            <property>
                <name>Deploy-Token</name>
                <value>{MWe9BlIgLlcHy+juc+KJWl8TxyE0e7bdimPH+8tX7ZVpqIrjHEAeU2ZO7Q2nDO3I}</value>
            </property>
        </httpHeaders>
    </configuration>
</server>
```

### Encrypt Nexus credentials

We'll encrypt the `bzhcamp` user's password.

1. Encrypt the password using `mvn --encrypt-password`
3. Replace the content of the `password` tag with the encrypted one
4. Add the corresponding section into your `settings.xml`

```xml
<server>
  <id>nexus-maven-registry</id>
  <username>bzhcamp</username>
  <password>{F5efohJ4GLIHmkBKmg3RHp6NVe7dyx+CARqP3+RyTkn3xS9hs2qy8csOjznzYnLp}</password>
</server>
```

## Run the example

### Build and upload `gcp-artifact`

```shell
cd gcp-artifact
mvn clean deploy -s ../settings.xml
```

⚠️ **It should be noted that authenticating to Gitlab maven repository with an encrypted token does not work out of the box** ⚠️

Maven [DefaultSettingsDecrypter](https://github.com/apache/maven/blob/master/maven-settings-builder/src/main/java/org/apache/maven/settings/crypto/DefaultSettingsDecrypter.java#L52-L106) components only decrypt :
* `//settings/servers/server/password`
* `//settings/servers/server/passphrase`
* `//settings/proxies/proxy/password`

In Gitlab case, the sensitive information is an `HTTP header`. This can be worked around by using a [Core maven extension](https://maven.apache.org/examples/maven-3-lifecycle-extensions.html) to alter maven behaviour.

See [./gitlab-artifact/.mvn/extensions.xml](./gitlab-artifact/.mvn/extensions.xml)

See also [Custom extension maven-settings-header-encryption](https://gitlab.com/syalioune/maven-settings-header-encryption)

### Build and upload `gitlab-artifact`

```shell
cd gitlab-artifact
mvn clean deploy -s ../settings.xml
```

### Build and upload `nexus-artifact`

```shell
cd nexus-artifact
mvn clean deploy -s ../settings.xml
```

### Build and run `main-artifact`

1. Manually clean your local repository `${user.home}/.m2/repository` to make sure that you're able to download artifact from registries

2. Build and run the artifact

```shell
cd main-artifact && \
mvn clean package -s ../settings.xml && \
java -jar target/main-artifact-1.0.jar
```

The output should be

```
Do something from GCP service
Do something from Gitlab service
Do something from Nexus service
```