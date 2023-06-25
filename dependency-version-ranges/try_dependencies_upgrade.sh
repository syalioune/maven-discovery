#/usr/bin/env bash

branch=$(echo upgrade/bump-versions-$(date +"%Y%m%d%H%M%S"))
git checkout -b $branch
mvn -X -f pom-ranges.xml versions:resolve-ranges
mv pom-ranges.xml pom.xml
mvn clean verify
cp pom-ranges.xml.versionsBackup pom-ranges.xml
git reset -- pom-ranges.xml
git add pom.xml
git commit -m "[chore] Bumping versions"
git diff master..$branch | cat
# git push
# Create MR