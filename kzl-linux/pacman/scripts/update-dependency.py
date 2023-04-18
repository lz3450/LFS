#!/usr/bin/python3

import os
import yaml

ROOT_DIRECTORY = '/home/kzl/LFS/kzl-linux/pacman/pkgbuilds/kzl'

PACKAGE_LIST = [
    'base', 'samba'
]


def generate_pkgbase_map(rootdir) -> dict:
    pkgbase_map = {}

    for subdir, dirs, files in os.walk(rootdir):
        for file in files:
            if file == 'PKGBUILD':
                pkgbuild_path = os.path.join(subdir, file)

                pkgbase = None
                pkgnames = []

                with open(pkgbuild_path, 'r') as f:
                    lines = f.readlines()

                for line in lines:
                    line = line.strip()
                    if line.startswith('pkgbase='):
                        pkgbase = line.split('=')[1].strip("'\"")
                    if line.startswith('pkgname=('):
                        if not line.endswith(")"):
                            raise SyntaxError("PKGBUILD: pkgname should be in one line.")
                        pkgnames = line[8:].strip("()").strip().replace("'", "").replace('"', "").split()
                        break

                if not pkgbase and pkgnames:
                    pkgbase = pkgnames[0]

                if pkgbase and pkgnames:
                    for pkgname in pkgnames:
                        pkgbase_map[pkgname] = pkgbase

    return pkgbase_map


def get_pkgbase(pkgname):
    if not hasattr(get_pkgbase, 'pkgbase_map'):
        get_pkgbase.pkgbase_map = generate_pkgbase_map(ROOT_DIRECTORY)

    return get_pkgbase.pkgbase_map.get(pkgname, pkgname)


def find_pkgbuild(pkgname):
    pkgbase = get_pkgbase(pkgname)
    return os.path.join(ROOT_DIRECTORY, pkgbase, 'PKGBUILD')


def parse_depends(pkgname):
    pkgbuild_path = find_pkgbuild(pkgname)

    if not os.path.isfile(pkgbuild_path):
        raise FileNotFoundError(f"PKGBUILD not found for {pkgname} in \"{pkgbuild_path}\"")

    depends = []
    with open(pkgbuild_path, 'r') as f:
        lines = f.readlines()

    in_depends = False
    for line in lines:
        line = line.strip()
        if line.startswith('depends=('):
            if not line.endswith(")"):
                in_depends = True
            depends.extend(line[8:].strip("()").strip().replace("'", "").replace('"', "").split())
            continue
        if in_depends:
            if line.endswith(')'):
                depends.extend(line.strip(')').strip().replace("'", "").replace('"', "").split())
                in_depends = False
                break
            else:
                depends.extend(line.replace("'", "").replace('"', "").split())

    return depends


def parse_makedepends(pkgname):
    pkgbuild_path = find_pkgbuild(pkgname)

    if not os.path.isfile(pkgbuild_path):
        raise FileNotFoundError(f"PKGBUILD not found for {pkgname} in \"{pkgbuild_path}\"")

    makedepends = []
    with open(pkgbuild_path, 'r') as f:
        lines = f.readlines()

    in_makedepends = False
    for line in lines:
        line = line.strip()
        if line.startswith('makedepends=('):
            if not line.endswith(")"):
                in_makedepends = True
            makedepends.extend(line[13:].strip("()").strip().replace("'", "").replace('"', "").split())
            continue
        if in_makedepends:
            if line.endswith(')'):
                makedepends.extend(line.strip(')').strip().replace("'", "").replace('"', "").split())
                in_makedepends = False
                break
            else:
                makedepends.extend(line.replace("'", "").replace('"', "").split())

    return makedepends


def compute_dependency_map(package_list: list, visited=None) -> list:
    if visited is None:
        visited = []

    if not package_list:
        return package_list

    dependency_map = []

    for pkgname in package_list:
        dependencies = []
        makedependencies = []
        formatted_dependencies = []
        if pkgname not in visited:
            dependencies = parse_depends(pkgname)
            makedependencies = parse_makedepends(pkgname)
            visited.append(pkgname)

        if dependencies:
            sub_dependencies_map = compute_dependency_map(dependencies, visited)
            # `sub_dependencies_map` is a list of dict
            # if the item is {'<pkgname>': []}, then append only '<pkgname>'
            # if the item is {'<pkgname>': ['<pkgname1>', '<pkgname2>', ...]}, then append the dict
            formatted_dependencies = [sub_dependencies_map[_] if sub_dependencies_map[_][pkg] else pkg for _, pkg in enumerate(dependencies)]
            # `dependencies` should be a list of str and dict
        if makedependencies:
            formatted_dependencies.extend([f'{makedepend} (make)' for makedepend in makedependencies])
            # sub_makedependencies_map = compute_dependency_map(makedependencies, visited)
            # formatted_dependencies.extend(
            #     [{f'{pkg} (make)': sub_makedependencies_map[_][pkg]}
            #      if sub_makedependencies_map[_][pkg] else f'{pkg} (make)'
            #      for _, pkg in enumerate(makedependencies)]
            # )
        dependency_map.append({pkgname: formatted_dependencies})

    return dependency_map


def dump_dependency_map(dependency_map: list, filename='packages.yaml'):
    yaml_map = {}
    for map in dependency_map:
        if isinstance(map, dict):
            yaml_map.update(map)
        elif isinstance(map, str):
            yaml_map.update({map: []})
    print(yaml_map)
    with open(filename, 'w') as f:
        yaml.dump(yaml_map, f, default_flow_style=False, sort_keys=False)


def dump_base():
    dependency_map = compute_dependency_map(['base'])
    print(dependency_map)
    dump_dependency_map(dependency_map[0]['base'], 'base.yaml')


def dump_package_list():
    dependency_map = compute_dependency_map(PACKAGE_LIST)
    print(dependency_map)
    dump_dependency_map(dependency_map)


def main():
    dump_base()
    # dump_package_list()


if __name__ == '__main__':
    main()
