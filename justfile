docpunct := "./bin/docpunct"

bootstrap:
    {{docpunct}} bootstrap

install feature:
    {{docpunct}} install {{feature}}

update feature:
    {{docpunct}} update {{feature}}

remove feature:
    {{docpunct}} remove {{feature}}

list:
    {{docpunct}} list

status:
    {{docpunct}} status

shellcheck:
    {{docpunct}} shellcheck

test-smoke:
    {{docpunct}} test-smoke

test-container ubuntu="24.04":
    {{docpunct}} test-container {{ubuntu}}

test-containers:
    {{docpunct}} test-containers

test-docker-feature ubuntu="24.04":
    {{docpunct}} test-docker-feature {{ubuntu}}

test-doublecmd-feature ubuntu="24.04":
    {{docpunct}} test-doublecmd-feature {{ubuntu}}

test:
    {{docpunct}} test

relink:
    {{docpunct}} relink
