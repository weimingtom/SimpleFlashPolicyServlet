#!/bin/sh

# see 
# http://maven.apache.org/guides/mini/guide-webapp.html

mvn archetype:generate -B -DgroupId=com.mycompany.app -DartifactId=my-webapp -DarchetypeArtifactId=maven-archetype-webapp
