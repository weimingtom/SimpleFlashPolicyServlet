#!/bin/sh

mvn -f my-webapp/pom.xml clean
rm -f my-webapp/src/main/webapp/*.swf
