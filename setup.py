#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""The setup script."""

import os

from setuptools import find_packages, setup


def parse_reqs(filepath):
    with open(filepath, "r") as f:
        reqstr = f.read()
    requirements = []
    for line in reqstr.splitlines():
        line = line.strip()
        if line == "":
            continue
        elif not line or line.startswith("#"):
            # comments are lines that start with # only
            continue
        elif line.startswith("-r") or line.startswith("--requirement"):
            _, new_filename = line.split()
            new_file_path = os.path.join(os.path.dirname(filepath or "."), new_filename)
            requirements.extend(parse_reqs(new_file_path))
        elif line.startswith("-f") or line.startswith("-i") or line.startswith("--"):
            continue
        elif line.startswith("-Z") or line.startswith("--always-unzip"):
            continue
        else:
            requirements.append(line)
    return requirements


version = "0.1.0"
readme = open("README.md").read()
requirements = parse_reqs("requirements.txt")
test_requirements = parse_reqs("requirements/test.txt")

setup(
    author="Corey Oordt",
    author_email="coreyoordt@gmail.com",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Natural Language :: English",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
    ],
    description="",
    install_requires=requirements,
    include_package_data=True,
    long_description=readme,
    long_description_content_type='text/markdown',
    keywords="adr",
    name="adr",
    entry_points="""
    [console_scripts]
    adr=adr.cli:cli
    """,
    packages=find_packages(
        exclude=["example*", "tests*", "docs", "build"],
        include=["adr*"],
    ),
    test_suite="tests",
    tests_require=test_requirements,
    url="https://github.com/coordt/adr",
    version=version,
    zip_safe=False,
)
