docpunct := "./bin/docpunct"

bootstrap:
    {{docpunct}} install core

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

relink:
    {{docpunct}} relink

