# Maven optional dependencies

**Since maven 2.2.0**

Maven introduced the notion of **optional** dependencies to account for situations where :

* A component's dependency requires transitive libraries for compilation
* We don't want to include them into our project because we don't use the subset of features they provide

This is best illustrated using the object diagram below

```plantuml
object my_driver_a
object my_driver_b
object my_driver_c
object my_orm
object my_core_feature

my_orm *-- my_driver_a #blue : strong dependency
my_orm *-- my_driver_b #blue : strong dependency

my_core_feature *-- my_orm #blue : strong dependency
my_core_feature *-- my_driver_c #blue : strong dependency
```

* The module `my_core_feature` depends on module `my_orm`
* The module `my_orm` depends on modules `my_driver_a` / `my_driver_b`
* The module `my_core_feature` want to use module `my_driver_c`

ℹ️ **Ideally, module `my_orm` should not depend directly on implementation modules `my_driver_a` and `my_driver_b`. However, the world is not perfect and legacy is everywhere** ℹ️

You can deal with that situations with two possible solutions.

## Solution without optional

```plantuml
object my_driver_a
object my_driver_b
object my_driver_c
object my_orm
object my_core_feature

my_orm *-- my_driver_a #blue : strong dependency
my_orm *-- my_driver_b #blue : strong dependency


my_core_feature *-- my_orm #blue : strong dependency
my_core_feature *-- my_driver_c #blue : strong dependency
```

1. Exclude unwanted transitive dependencies from `my_orm` dependency

```xml
<dependencies>
    <dependency>
        <groupId>com.syalioune</groupId>
        <artifactId>my-orm</artifactId>
        <version>1.0</version>
        <exclusions>
            <exclusion>
                <groupId>com.syalioune.db.driver</groupId>
                <artifactId>*</artifactId>
            </exclusion>
        </exclusions>
    </dependency>
    <dependency>
        <groupId>com.syalioune.db.driver</groupId>
        <artifactId>my-db-driver-c</artifactId>
        <version>1.0</version>
    </dependency>
</dependencies>
```

2. Show module dependency tree

```
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ my-core-feature ---
[INFO] com.syalioune:my-core-feature:jar:1.0
[INFO] +- com.syalioune:my-orm:jar:1.0:compile
[INFO] \- com.syalioune.db.driver:my-db-driver-c:jar:1.0:compile
```


## Solution with optional dependency

```plantuml
object my_driver_a
object my_driver_b
object my_driver_c
object my_orm_with_optionals
object my_core_feature_with_optionals

my_orm_with_optionals *.. my_driver_a #green : optional dependency
my_orm_with_optionals *.. my_driver_b #green : optional dependency

my_core_feature_with_optionals *-- my_orm_with_optionals #blue : strong dependency
my_core_feature_with_optionals *-- my_driver_c #blue : strong dependency
```

1. Declare `my-db-driver-a` and `my-db-driver-b` as **optional**  in `my-orm-with-optionals`

```xml
<dependencies>
    <dependency>
        <groupId>com.syalioune.db.driver</groupId>
        <artifactId>my-db-driver-a</artifactId>
        <version>1.0</version>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>com.syalioune.db.driver</groupId>
        <artifactId>my-db-driver-b</artifactId>
        <version>1.0</version>
        <optional>true</optional>
    </dependency>
</dependencies>
```

2. Include `my-orm-with-optionals` without fuss in `my-core-feature-with-optionals`

```xml
<dependencies>
    <dependency>
        <groupId>com.syalioune</groupId>
        <artifactId>my-orm</artifactId>
        <version>1.0</version>
    </dependency>
    <dependency>
        <groupId>com.syalioune.db.driver</groupId>
        <artifactId>my-db-driver-c</artifactId>
        <version>1.0</version>
    </dependency>
</dependencies>
```

3. Show module dependency tree

```
[INFO] --- maven-dependency-plugin:2.8:tree (default-cli) @ my-core-feature-with-optionals ---
[INFO] com.syalioune:my-core-feature-with-optionals:jar:1.0
[INFO] +- com.syalioune:my-orm-with-optionals:jar:1.0:compile
[INFO] \- com.syalioune.db.driver:my-db-driver-c:jar:1.0:compile
```