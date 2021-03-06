#!/usr/bin/env python3
"""validate data.yaml against schema.yaml"""

from os import path

import yaml
from jsonschema import FormatChecker, validate, ValidationError


class NoDatesSafeLoader(yaml.SafeLoader):
    """Disable parsing dates
    By default PyYAML will automatically cast the expiry_date to a datetime
    object which will fail the jsonschema format check (str_types = str):
        https://github.com/Julian/jsonschema/blob/master/jsonschema/_format.py#L331-L335
    This occurs because as jsonschema dose not have a datetime type.  instead
    it has a string type with a date format.
    Stolen from:
        https://stackoverflow.com/a/37958106/3075306"""
    @classmethod
    def remove_implicit_resolver(cls, tag_to_remove):
        """remove resolver"""
        if 'yaml_implicit_resolvers' not in cls.__dict__:
            cls.yaml_implicit_resolvers = cls.yaml_implicit_resolvers.copy()
        for first_letter, mappings in cls.yaml_implicit_resolvers.items():
            cls.yaml_implicit_resolvers[first_letter] = [
                (tag, regexp) for tag, regexp in mappings if tag != tag_to_remove]


def main():
    """Main Entry point"""
    ansi_fail = '\033[91m'
    ansi_ok = '\033[92m'
    ansi_end = '\033[0m'
    NoDatesSafeLoader.remove_implicit_resolver('tag:yaml.org,2002:timestamp')
    cwd = path.dirname(path.realpath(__file__))
    schema_path = path.join(cwd, 'schema.yaml')
    data_path = path.join(cwd, 'data.yaml')
    try:
        schema = yaml.safe_load(open(schema_path))
        # don't convert dates
        data = yaml.load(open(data_path), Loader=NoDatesSafeLoader)
        validate(data, schema, format_checker=FormatChecker())
    except yaml.YAMLError as error:
        print('{}FAIL: unable load yaml file:\n{}{}'.format(
            ansi_fail, error, ansi_end))
        return 1
    except ValidationError as error:
        print('{}FAIL: unable to validate data.yaml:\n{}{}'.format(
            ansi_fail, error, ansi_end))
        return 1
    print('{}PASS: data.yaml validates{}'.format(
        ansi_ok, ansi_end))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
