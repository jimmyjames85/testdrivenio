#!/bin/bash

env=$1
file=""
fails=""


if [[ "${env}" == "stage" ]]; then
    file="docker-compose.yml"
elif [[ "${env}" == "dev" ]]; then
    file="docker-compose.yml"
elif [[ "${env}" == "prod" ]]; then
    file="docker-compose-prod.yml"
else
    echo "USAGE: sh test.sh environment_name"
    echo "* environment_name: must either be 'dev', 'stage', or 'prod'"
    exit 1
fi


inspect() {
    if [ $1 -ne 0 ]; then
	fails="${fails} $2"
    fi
}

docker-compose -f $file up -d --build
# TODO waitforit DB
sleep 4

docker-compose -f $file run users python manage.py test | 2>&1 tail -1 | grep OK
inspect $? users
docker-compose -f $file run users flake8 --ignore=E501 project
inspect $? users-lint


if [[ "${env}" == "dev" ]]; then
    docker-compose -f $file run client npm test -- --coverage
    inspect $? client
    testcafe chrome e2e
    inspect $? e2e
else
    testcafe chrome e2e/index.test.js
    inpect $? e2e
fi


if [ -n "${fails}" ]; then
    echo "Tests failed: ${fails}"
    exit 1
else
    echo "Tests passed!"
    exit 0
fi
