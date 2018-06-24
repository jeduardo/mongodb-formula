{%- from 'mongodb/map.jinja' import mdb with context -%}

install pymongo package:
  pkg.installed:
    - name: python-pymongo

# Collect admin user information
{%- set ctx = {} %}
{%- for user, properties in mdb.users.items() %}
{%- if user == 'admin' %}
{%- for prop in properties %}
# {{ prop.keys() }} {{ 'passwd' in prop.keys() }}
{%- if 'passwd' in prop.keys() %}
# {{ prop['passwd'] }}
{%- do ctx.update({'mongodb_admin_pwd': prop['passwd']}) %}
{%- endif %}
{%- endfor %}
{%- endif%}
{%- endfor %}

# Manage users
{%- for user, properties in mdb.users.items() %}
add user {{ user }}:
  {%- if 'absent' in properties %}
  {%- set action = 'absent' %}
  {%- else %}
  {%- set action = 'present' %}
  {%- endif %}
  mongodb_user.{{ action }}:
    - name: {{ user }}
    {{ properties | yaml(False) | indent(4) }}
    {%- if user != 'admin' %}
    # Details of the admin user for maintenance
    - user: admin
    - password: {{ ctx.mongodb_admin_pwd }}
    - authdb: admin
    {%- endif %}
    - require:
      {%- if user != 'admin' %}
      - mongodb_user: add user admin
      {%- endif %}
      - pkg: install pymongo package
{%- endfor %}