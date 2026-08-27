#!/usr/bin/env python3
"""
Generate Python module list from testcontainers-python pyproject.toml
Outputs markdown table for Modules-INDEX.md
"""

import toml
import sys
from pathlib import Path

def generate_python_modules():
    pyproject_path = Path("/home/bruno/ai-lab/testcontainers-python/pyproject.toml")
    output_path = Path("/Users/bruno.lima/opencode/main/testcontainers-devlog/testcontainers-vault/tables/python-modules.md")
    
    if not pyproject_path.exists():
        print(f"Error: {pyproject_path} not found")
        sys.exit(1)
    
    with open(pyproject_path, 'r') as f:
        data = toml.load(f)
    
    # Try to find module definitions in pyproject.toml
    # Look for module definitions in various possible locations
    modules = []
    
    # Check for module definitions in various places
    if 'tool' in data and 'testcontainers' in data['tool']:
        tc_config = data['tool']['testcontainers']
        if 'modules' in tc_config:
            for module in tc_config['modules']:
                modules.append(module)
    
    # Also scan the modules directory
    modules_dir = Path("/home/bruno/ai-lab/testcontainers-python/src/testcontainers/modules")
    if modules_dir.exists():
        for module_file in modules_dir.glob("*.py"):
            module_name = module_file.stem
            if module_name in ['__init__', '__pycache__']:
                continue
            
            # Try to extract class name and description
            content = module_file.read_text()
            class_name = None
            desc = ""
            
            # Find class definition
            for line in content.split('\n'):
                if line.strip().startswith('class '):
                    class_name = line.split('class ')[1].split('(')[0].split(':')[0].strip()
                    break
            
            # Extract docstring
            if '"""' in content:
                docstring = content.split('"""')[1] if content.count('"""') >= 2 else ""
                desc = docstring.strip()[:100]
            
            modules.append({
                'name': module_name,
                'class': class_name or module_name.capitalize(),
                'description': desc or f"Container for {module_name}"
            })
    
    # Categorize modules
    def categorize(name):
        name_lower = name.lower()
        if any(x in name_lower for x in ['postgres', 'mysql', 'maria', 'oracle', 'sqlserver', 'cockroach', 'clickhouse', 'cratedb', 'db2', 'databend', 'presto', 'trino', 'tidb', 'yugabyte', 'oceanbase', 'cassandra', 'couchbase', 'influx', 'neo4j', 'orient', 'scylla']):
            return "Databases (SQL)" if 'postgres' in name_lower or 'mysql' in name_lower or 'maria' in name_lower or 'oracle' in name_lower or 'sqlserver' in name_lower else "Databases (NoSQL)"
        elif any(x in name_lower for x in ['kafka', 'rabbit', 'pulsar', 'redis']):
            return "Message Queues"
        elif any(x in name_lower for x in ['localstack', 'gcloud', 'azure', 'vault', 'consul', 'k3s', 'ollama', 'openfga', 'minio']):
            return "Cloud/Infra"
        elif any(x in name_lower for x in ['elastic', 'clickhouse', 'questdb', 'presto', 'trino', 'influx', 'grafana', 'prometheus']):
            return "Search/Analytics"
        elif any(x in name_lower for x in ['selenium', 'webdriver', 'playwright']):
            return "Web/UI"
        else:
            return "Specialized"
    
    # Generate markdown
    output = "| Module | Category | Description | Status |\n"
    output += "|--------|----------|-------------|--------|\n"
    
    for module in sorted(modules, key=lambda x: x.get('name', '')):
        name = module.get('name', '')
        if not name:
            continue
        category = categorize(name)
        desc = module.get('description', f"Container for {name}")
        status = "✅"
        output += f"| {name} | {category} | {desc} | {status} |\n"
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(output)
    print(f"Generated {output_path}")

if __name__ == "__main__":
    generate_python_modules()