# Maven reactor improvements

**Since maven 4.0.0**

Considering the following modules relationships.

```plantuml
object reactor_improvements
object failing_module
object common
object project_a
object project_a_api
object project_a_impl
object project_b
object project_b_api
object project_b_impl

reactor_improvements *-- project_a #tomato : child
reactor_improvements *-- project_b #tomato : child
reactor_improvements *-- failing_module #tomato : child
project_a *-- project_a_api #tomato : child
project_a *-- project_a_impl #tomato : child
project_a_impl *-- common #blue : depends_on
project_b *-- project_b_api #tomato : child
project_b *-- project_b_impl #tomato : child
project_b_impl *-- common #blue : depends_on
project_b_api -right-* project_a_impl #blue : depends_on
project_b_api -left-* project_b_impl #blue : depends_on
project_a_api -left-* project_a_impl #blue : depends_on
```

Maven added some improvements into **Reactor** that you can find in [Guide to multiple modules 4](https://maven.apache.org/guides/mini/guide-multiple-modules-4.html) 

## Build the parent module

### Maven 3.8.1

1. Build the module

```shell
mvn clean install
```

2. Look at reactor build order

```
[INFO] Reactor Build Order:
[INFO] 
[INFO] reactor-improvements                                               [pom]
[INFO] failing-module                                                     [jar]
[INFO] project-a                                                          [pom]
[INFO] project-a-api                                                      [jar]
[INFO] common                                                             [jar]
[INFO] project-b                                                          [pom]
[INFO] project-b-api                                                      [jar]
[INFO] project-a-impl                                                     [jar]
[INFO] project-b-impl                                                     [jar]
```

## Maven 4.0.0-alpha-5

1. Build the module

```shell
mvn clean install
```

2. Look at reactor build order

```
[INFO] Reactor Build Order:
[INFO] 
[INFO] reactor-improvements                                               [pom]
[INFO] failing-module                                                     [jar]
[INFO] project-a                                                          [pom]
[INFO] project-a-api                                                      [jar]
[INFO] common                                                             [jar]
[INFO] project-b                                                          [pom]
[INFO] project-b-api                                                      [jar]
[INFO] project-a-impl                                                     [jar]
[INFO] project-b-impl                                                     [jar]
```

ℹ️ **Identical behavior** ℹ️

## Deal with failure

🛎️ **Uncomment the method below in** [Failing.java](./failing-module/src/main/java/com/syalioune/Failing.java)

```java
public String failingMethod() {
    System.out.println("Uncomment this method to trigger failure");
}
```

### Maven 3.8.1

1. Build the module

```shell
mvn clean install --fail-at-end
```

2. Look at reactor summary

```
[INFO] reactor-improvements ............................... SUCCESS [  0.422 s]
[INFO] failing-module ..................................... FAILURE [  1.641 s]
[INFO] project-a .......................................... SUCCESS [  0.058 s]
[INFO] project-a-api ...................................... SUCCESS [  1.204 s]
[INFO] common ............................................. SUCCESS [  1.263 s]
[INFO] project-b .......................................... SUCCESS [  0.019 s]
[INFO] project-b-api ...................................... SUCCESS [  0.223 s]
[INFO] project-a-impl ..................................... SUCCESS [  0.208 s]
[INFO] project-b-impl ..................................... SUCCESS [  0.348 s]
```

### Maven 4

1. Build the module

```shell
mvn clean install --fail-at-end
```

2. Look at reactor summary

```
[INFO] reactor-improvements ............................... SUCCESS [  0.422 s]
[INFO] failing-module ..................................... FAILURE [  1.641 s]
[INFO] project-a .......................................... SUCCESS [  0.058 s]
[INFO] project-a-api ...................................... SUCCESS [  1.204 s]
[INFO] common ............................................. SUCCESS [  1.263 s]
[INFO] project-b .......................................... SUCCESS [  0.019 s]
[INFO] project-b-api ...................................... SUCCESS [  0.223 s]
[INFO] project-a-impl ..................................... SUCCESS [  0.208 s]
[INFO] project-b-impl ..................................... SUCCESS [  0.348 s]
```

ℹ️ **Identical behavior** ℹ️

## Resume after failure

### Maven 3.8.1

1. Provide the `--resume-from` flag along with the module to resume from

```shell
mvn clean install --fail-at-end --resume-from failing-module
```

2. Check reactor output

```
[INFO] Reactor Build Order:
[INFO] 
[INFO] failing-module                                                     [jar]
[INFO] project-a                                                          [pom]
[INFO] project-a-api                                                      [jar]
[INFO] common                                                             [jar]
[INFO] project-b                                                          [pom]
[INFO] project-b-api                                                      [jar]
[INFO] project-a-impl                                                     [jar]
[INFO] project-b-impl                                                     [jar]
```

⚠️ **Even though the failing module was provided, maven reactor will still clean and install (without compiling/packaging) other modules** ⚠️

### Maven 4

1. Provide only the `--resume` flag without specifying the module

```shell
mvn clean install --fail-at-end --resume
```

2. Check reactor output

```
[INFO] Scanning for projects...
[INFO] Resuming from com.syalioune:failing-module due to the --resume / -r feature.
```

ℹ️ **Maven really resume only from the failing module** ℹ️

## Build `project-a-impl`

### Maven 3.8.1

1. Make sure to clean you local repository

```shell
rm -rf ~/.m2/repository/com/syalioune
```

2. Try to build only the `project-a-impl` module

```shell
cd project-a/project-a-impl
mvn clean install --also-make
```

3. The build fails

```shell
[INFO] Scanning for projects...
[INFO] 
[INFO] Using the MultiThreadedBuilder implementation with a thread count of 3
[INFO] 
[INFO] --------------------< com.syalioune:project-a-impl >--------------------
[INFO] Building project-a-impl 1.0
[INFO] --------------------------------[ jar ]---------------------------------
Downloading from central: https://repo.maven.apache.org/maven2/com/syalioune/common/1.0/common-1.0.pom
[WARNING] The POM for com.syalioune:common:jar:1.0 is missing, no dependency information available
Downloading from central: https://repo.maven.apache.org/maven2/com/syalioune/project-b-api/1.0/project-b-api-1.0.pom
[WARNING] The POM for com.syalioune:project-b-api:jar:1.0 is missing, no dependency information available
Downloading from central: https://repo.maven.apache.org/maven2/com/syalioune/common/1.0/common-1.0.jar
Downloading from central: https://repo.maven.apache.org/maven2/com/syalioune/project-b-api/1.0/project-b-api-1.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.659 s (Wall Clock)
[INFO] Finished at: 2023-06-25T19:56:00+02:00
[INFO] ------------------------------------------------------------------------ 
```

ℹ️ **You need to perform a global `mvn clean install` on the parent modules before** ℹ️ 

### Maven 4

1. Create an empty `.mvn` at the root of `reactor-improvements` module.

2. Make sure to clean you local repository

```shell
rm -rf ~/.m2/repository/com/syalioune
```

3. Try to build only the `project-a-impl` module

```shell
cd project-a/project-a-impl
mvn clean install --also-make
```

3. The build succeed

```shell
[INFO] Reactor Build Order:
[INFO] 
[INFO] reactor-improvements                                               [pom]
[INFO] project-a                                                          [pom]
[INFO] common                                                             [jar]
[INFO] project-b                                                          [pom]
[INFO] project-b-api                                                      [jar]
[INFO] project-a-impl                                                     [jar] 
```

```plantuml
skinparam object {
    BorderColor<<built>> green
    FontColor<<built>> green
    BorderColor<<target>> green
    BorderThickness<<target>> 3
    FontColor<<target>> green
}

object reactor_improvements <<built>>
note right of reactor_improvements : **1**
object failing_module
object common <<built>>
note left of common : **4**
object project_a <<built>>
note left of project_a : **2**
object project_a_api <<built>>
note right of project_a_api : **3**
object project_a_impl <<target>>
note bottom of project_a_impl : **7**
object project_b <<built>>
note right of project_b : **5**
object project_b_api <<built>>
note bottom of project_b_api : **6**
object project_b_impl

reactor_improvements *-- project_a #tomato : child
reactor_improvements *-- project_b #tomato : child
reactor_improvements *-- failing_module #tomato : child
project_a *-- project_a_api #tomato : child
project_a *-- project_a_impl #tomato : child
project_a_impl *-- common #blue : depends_on
project_b *-- project_b_api #tomato : child
project_b *-- project_b_impl #tomato : child
project_b_impl *-- common #blue : depends_on
project_b_api -right-* project_a_impl #blue : depends_on
project_b_api -left-* project_b_impl #blue : depends_on
project_a_api -left-* project_a_impl #blue : depends_on
```

ℹ️ **The important items to make it work are the `.mvn` folder to mark the top-level module for maven and the `--also-make` to build dependencies of `project-a-impl` before** ℹ️

## Build `common`

### Maven 3.8.1

1. Build the `common` module

```shell
cd common
mvn clean install --also-make-dependents
```

2. Check reactor output

```
[INFO] Scanning for projects...
[INFO] 
[INFO] Using the MultiThreadedBuilder implementation with a thread count of 3
[INFO] 
[INFO] ------------------------< com.syalioune:common >------------------------
[INFO] Building common 1.0
[INFO] --------------------------------[ jar ]---------------------------------
```

### Maven 4

1. Build the `common` module

```shell
cd common
mvn clean install --also-make-dependents
```

2. Check reactor output

```
[INFO] Scanning for projects...
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Build Order:
[INFO] 
[INFO] common                                                             [jar]
[INFO] project-a-impl                                                     [jar]
[INFO] project-b-impl                                                     [jar]
[INFO] 
[INFO] Using the MultiThreadedBuilder implementation with a thread count of 3
```

```plantuml
skinparam object {
    BorderColor<<built>> green
    FontColor<<built>> green
    BorderColor<<target>> green
    BorderThickness<<target>> 3
    FontColor<<target>> green
}

object reactor_improvements
object failing_module
object common <<target>>
note left of common : **1**
object project_a
object project_a_api
object project_a_impl <<built>>
note bottom of project_a_impl : **2**
object project_b
object project_b_api
object project_b_impl <<built>>
note left of project_b_impl : **3**

reactor_improvements *-- project_a #tomato : child
reactor_improvements *-- project_b #tomato : child
reactor_improvements *-- failing_module #tomato : child
project_a *-- project_a_api #tomato : child
project_a *-- project_a_impl #tomato : child
project_a_impl *-- common #blue : depends_on
project_b *-- project_b_api #tomato : child
project_b *-- project_b_impl #tomato : child
project_b_impl *-- common #blue : depends_on
project_b_api -right-* project_a_impl #blue : depends_on
project_b_api -left-* project_b_impl #blue : depends_on
project_a_api -left-* project_a_impl #blue : depends_on
```

ℹ️ **The important items to make it work are the `.mvn` folder to mark the top-level module for maven and the `--also-make-dependents` to build modules that depends_on `common` after** ℹ️

## Credits ©️

- [Marten Mulders](https://maarten.mulders.it/2020/11/whats-new-in-maven-4/)