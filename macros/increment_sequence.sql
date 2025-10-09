# in macros/increment_sequence.sql

{%- macro increment_sequence() -%}

    {{ this.database }}.{{ this.schema }}.{{ this.name }}_seq.nextval

{%- endmacro -%}