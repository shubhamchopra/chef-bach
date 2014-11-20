import itertools
import subprocess
from string import Template

""" Script to generate an HTML file with a listing of hosts by role and which recipes are installed """

def read_machines():
  """ Return a dictionary of machine name keys with dictionaries as values calling out to knife(1) to find all hosts
      Each machine dictionary value is has keys name, roles and recipes with lists of associated values:
      machines = {"host":
                    {"name": "foo.com",
                     "roles": ["Foo-Host", "Foo-Server"],
                     "recipes": ["foo_server::good","foo_host::yup","apt::default"]},
                  ...
                 }
  """
  machines={}
  node_cmd = subprocess.Popen(["knife", "node", "list"], stdout=subprocess.PIPE)
  node_list = node_cmd.communicate()[0]
  for n in node_list.split('\n'):
    n = n.strip()
    node_info_cmd = _cmd = subprocess.Popen(["knife", "node", "show", n], stdout=subprocess.PIPE)
    node_info = node_info_cmd.communicate()[0]

    for l in node_info.split('\n'):
      l = l.strip()
      if l.startswith('FQDN:'):
        host = l.rsplit(' ',1)[-1]
        machines.setdefault(host, {}).update({"name": host})
      elif l.startswith('Recipes:'):
        recipes = {'recipes': [i.strip(",") for i in l.rsplit(' ') if i not in ('','Recipes:')]}
        machines.setdefault(host, {}).update(recipes)
      elif l.startswith('Roles:'):
        roles = {'roles': [i.strip(",") for i in l.rsplit(' ') if i not in ('','Roles:')]}
        machines.setdefault(host, {}).update(roles)
  return machines

def print_table():
  """ Return a string of HTML """
  machines = read_machines()
  table_preamble = '<html><body><table>'
  table_postscript = '</table></body></html>'
  print table_preamble
  for r in print_roles(machines):
    print r
  print table_postscript

def print_roles(machines):
  """ Yields each role table body as a string given a machines dictionary """
  section = Template('<thead><tr><th colspan="$recipe_count">$section_type: $section_name</th></tr><tr><th>Machine</th>$recipes</tr></thead><tbody>$machine_data</tbody>')
  roles = list(set(itertools.chain.from_iterable((v['roles'] for v in machines.values()))))
  roles.sort()
  for r in roles:
    # only get recipes for machines in this role
    role_machines = [m for m in machines.values() if r in m['roles']]
    recipes = set(itertools.chain.from_iterable((v['recipes'] for v in role_machines)))
    yield section.substitute(recipe_count = len(recipes),
                             section_type = 'Role',
                             section_name = r,
                             recipes = create_html_items('th', recipes),
                             machine_data = create_html_items('tr', (generate_machine_listings(m, recipes) for m in role_machines)))

def create_html_items(tag, items):
  """ Return a string for tags (e.g. <tr>foo</tr><tr>bar</tr>) """
  return ' '.join(('<%s>%s</%s>' % (tag, i, tag) for i in items))

def generate_machine_listings(machine, recipes):
  """ Return a string of table data items give a machine dictionary and a particular recipe """
  return str(create_html_items('td',
                 [machine['name']] + ['Yes' if r in machine["recipes"] else 'No' for r in recipes]))

print_table()
