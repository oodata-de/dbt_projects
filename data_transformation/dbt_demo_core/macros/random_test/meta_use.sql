{% macro meta_use(node_resource_type="model") %}
	{% if execute %}
 
        {% set meta_columns = {} %}
        {% set node_unique_id = model.unique_id | string %}
        --- Get all column in model
        {% if node_resource_type == "source" %} 
            {% set columns = graph.sources[node_unique_id]['columns']  %}
        {% else %}
            {% set columns = graph.nodes[node_unique_id]['columns']  %}
        {% endif %}
        
        -- Loop through column list to get specific attributes of the column defined in yml
        {% if columns|length > 0 %}:
            {{ log("columns in model: " ~ columns, info=true) }}
            {% for column in columns if columns|length > 0 %}
                {% set datatype = graph.nodes[node_unique_id]['columns'][column]['data_type'] %}
                {{ log("column: " ~ column ~ " datatype: " ~ datatype, info=true) }}

                {% set col_datatype = {column:datatype} %}
                {{ log("datatype mapping for column " ~ column ~ ": " ~ col_datatype, info=true) }}

                {% do meta_columns.update(col_datatype) %}
            {% endfor %}

            {{ return(meta_columns) }}
        {% else %}
            {{ log("No columns found in model: " ~ node_unique_id, info=true) }}
        {% endif %}
        
    {% endif %}
{% endmacro %}