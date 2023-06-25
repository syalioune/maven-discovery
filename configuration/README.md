# Maven configuration helper

There are various aspect of maven that you can configure using `CLI args` or environment variable.

* Maven JVM through `MAVEN_OPTS` environment variable (e.g. `-Xms256m`)
* Build tool options (e.g. `--fail-at-end`)
* Extension loading (e.g. `-Dmaven.ext.class.path=extension.jar`)

It can be hard to share a common set of arguments/options between developers in a team. Let alone maintain consistency across environment (i.e. local dev workstation and CI box)

Recent versions of maven allow to define and easily share common build args with a set of files that you can store in your VCS.

## `.mvn` directory

This folder can be set at the root of any maven module of your project. Either at the top level or at child module level.

### Common JVM config

**Since 3.3.1**

You can create a `.mvn/jvm.config` file containing project-wide maven JVM options in one line.

See [./.mvn/jvm.config](.mvn/jvm.config)

### Common maven options

**Since 3.3.1**

You can create a `.mvn/maven.config` file containing project-wide maven CLI options in one line.

See [./.mvn/maven.config](.mvn/maven.config)

ℹ️ **The arguments should be in seperate lines starting maven 3.9.0** ℹ️

### Common extension loading

**Since 3.2.5**

You can create a `.mvn/extensions.xml` file containing project-wide maven extensions.

See [./.mvn/extensions.xml](../.mvn/extensions.xml)

## Behavior in multi-module projects

Maven generally honor the nearest `.mvn` folder from its execution root.

The different configuration files **are not** merged to produce a consolidated version.

ℹ️ **Tested with maven 3.9.2** ℹ️

```
├── pom.xml
├── .mvn
│   ├── extensions.xml
│   ├── jvm.config
│   └── maven.config
├── configuration
│   ├── pom.xml
│   ├── .mvn
│   │   ├── extensions.xml
│   │   ├── jvm.config
│   │   └── maven.config
```

* `./.mvn` will be used if you do a `mvn clean install` for example
* `./configuration/.mvn` will be used if you do a `cd configuration && mvn clean install` for example

## CLI override

Maven honor options passed through the CLI.

ℹ️ **Tested with maven 3.9.2** ℹ️

The [pom.xml](./xml) contains the following variable section.

```xml
<version>${revision}</version>
```

* When issuing `mvn clean install`, maven retrieves the property value from [.mvn/maven.config](.mvn/maven.config)
* When issuing `mvn clean install -Drevision=from-cli`, maven retrieves the property value from the CLI

## Practice

```shell
mvn clean install
```

or 

```shell
mvn clean install -Drevision=from-cli
```