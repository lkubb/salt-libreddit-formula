# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_clean = tplroot ~ '.config.clean' %}
{%- from tplroot ~ "/map.jinja" import mapdata as libreddit with context %}

include:
  - {{ sls_config_clean }}

{%- if libreddit.install.autoupdate_service %}

Podman autoupdate service is disabled for Libreddit:
{%-   if libreddit.install.rootless %}
  compose.systemd_service_disabled:
    - user: {{ libreddit.lookup.user.name }}
{%-   else %}
  service.disabled:
{%-   endif %}
    - name: podman-auto-update.timer
{%- endif %}

Libreddit is absent:
  compose.removed:
    - name: {{ libreddit.lookup.paths.compose }}
    - volumes: {{ libreddit.install.remove_all_data_for_sure }}
{%- for param in ["project_name", "container_prefix", "pod_prefix", "separator"] %}
{%-   if libreddit.lookup.compose.get(param) is not none %}
    - {{ param }}: {{ libreddit.lookup.compose[param] }}
{%-   endif %}
{%- endfor %}
{%- if libreddit.install.rootless %}
    - user: {{ libreddit.lookup.user.name }}
{%- endif %}
    - require:
      - sls: {{ sls_config_clean }}

Libreddit compose file is absent:
  file.absent:
    - name: {{ libreddit.lookup.paths.compose }}
    - require:
      - Libreddit is absent

Libreddit user session is not initialized at boot:
  compose.lingering_managed:
    - name: {{ libreddit.lookup.user.name }}
    - enable: false
    - onlyif:
      - fun: user.info
        name: {{ libreddit.lookup.user.name }}

Libreddit user account is absent:
  user.absent:
    - name: {{ libreddit.lookup.user.name }}
    - purge: {{ libreddit.install.remove_all_data_for_sure }}
    - require:
      - Libreddit is absent
    - retry:
        attempts: 5
        interval: 2

{%- if libreddit.install.remove_all_data_for_sure %}

Libreddit paths are absent:
  file.absent:
    - names:
      - {{ libreddit.lookup.paths.base }}
    - require:
      - Libreddit is absent
{%- endif %}
