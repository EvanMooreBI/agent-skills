"""Strict skill metadata contract, vendored for independently usable packages.

The creator, tester, and distribution copies are kept identical by parity tests.
Requirements: Agent Skills specification and Claude Code skills reference,
checked 2026-11-07. Repository style recommendations are not format errors.
"""

import re

try:
    import yaml
except ImportError:
    yaml = None


PORTABLE_FIELDS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
CODE_FIELDS = {
    "when_to_use", "argument-hint", "arguments", "disable-model-invocation",
    "user-invocable", "disallowed-tools", "model", "effort", "context", "agent",
    "background", "hooks", "paths", "shell",
}
NAME_PATTERN = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\Z")


def parse_skill(content):
    """Return metadata and body; fail closed on ambiguous or malformed YAML."""
    if yaml is None:
        raise ValueError("PyYAML is required; install it with python -m pip install pyyaml")
    lines = content.splitlines()
    if not lines or lines[0] != "---":
        raise ValueError("SKILL.md must start with YAML frontmatter on its first line")
    end = next((i for i, line in enumerate(lines[1:], 1) if line == "---"), None)
    if end is None:
        raise ValueError("Frontmatter closing marker not found")

    class UniqueKeyLoader(yaml.SafeLoader):
        pass

    def mapping(loader, node, deep=False):
        loader.flatten_mapping(node)
        result = {}
        for key_node, value_node in node.value:
            key = loader.construct_object(key_node, deep=deep)
            try:
                if key in result:
                    raise ValueError(f"Duplicate YAML key: {key!r}")
                result[key] = loader.construct_object(value_node, deep=deep)
            except TypeError as exc:
                raise ValueError("YAML mapping keys must be scalar values") from exc
        return result

    UniqueKeyLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)
    try:
        metadata = yaml.load("\n".join(lines[1:end]), Loader=UniqueKeyLoader)
    except yaml.YAMLError as exc:
        raise ValueError(f"Invalid YAML frontmatter: {exc}") from exc
    if not isinstance(metadata, dict):
        raise ValueError("Frontmatter must be a YAML mapping")
    return metadata, "\n".join(lines[end + 1:]).strip()


def _string_list(value):
    return isinstance(value, str) or (
        isinstance(value, list) and all(isinstance(item, str) for item in value)
    )


def _code_boolean(value):
    if isinstance(value, bool):
        return True
    if type(value) is int:
        return value in (0, 1)
    return isinstance(value, str) and value.lower() in {"true", "false", "yes", "no", "on", "off", "1", "0"}


def validate_fields(metadata, folder_name, target="repo"):
    """Return structural errors for repo/Claude Code or portable packaging."""
    if target not in {"repo", "portable"}:
        raise ValueError(f"Unknown validation target: {target}")
    errors = []
    if not all(isinstance(key, str) for key in metadata):
        return ["Frontmatter field names must be strings"]
    allowed = PORTABLE_FIELDS | (CODE_FIELDS if target == "repo" else set())
    unknown = set(metadata) - allowed
    if unknown:
        errors.append(f"Unsupported frontmatter fields for {target}: {', '.join(sorted(unknown))}")

    name = metadata.get("name")
    if not isinstance(name, str) or not 1 <= len(name) <= 64 or not NAME_PATTERN.fullmatch(name):
        errors.append("Frontmatter name must be 1-64 characters using lowercase letters, numbers, and hyphens only; no leading, trailing, or consecutive hyphens")
    if isinstance(name, str) and name != folder_name:
        errors.append(f"Frontmatter name {name!r} does not match folder name {folder_name!r}")
    description = metadata.get("description")
    if not isinstance(description, str) or not description.strip() or len(description) > 1024:
        errors.append("Frontmatter description must be a nonempty string of 1-1024 characters")
    for field in ("license", "compatibility"):
        if field in metadata:
            value = metadata[field]
            if not isinstance(value, str) or not value.strip() or (field == "compatibility" and len(value) > 500):
                errors.append(f"{field} must be a nonempty string" + (" of at most 500 characters" if field == "compatibility" else ""))
    if "metadata" in metadata:
        value = metadata["metadata"]
        if not isinstance(value, dict) or not all(isinstance(key, str) for key in value):
            errors.append("metadata must be a mapping with string keys")
        elif target == "portable" and not all(isinstance(item, str) for item in value.values()):
            errors.append("Portable metadata values must be strings")
    if "allowed-tools" in metadata:
        value = metadata["allowed-tools"]
        if not (isinstance(value, str) if target == "portable" else _string_list(value)):
            errors.append("allowed-tools must be a string" + (" or list of strings" if target == "repo" else ""))

    if target == "portable":
        for field in ("name", "description"):
            value = metadata.get(field)
            if isinstance(value, str) and re.search(r"<[^>]*>", value):
                errors.append(f"Portable {field} must not contain XML tags")
        if isinstance(name, str) and any(word in name for word in ("anthropic", "claude")):
            errors.append("Portable upload name must not contain reserved words anthropic or claude")
        return errors

    for field in ("when_to_use", "argument-hint", "model", "agent"):
        if field in metadata and not isinstance(metadata[field], str):
            errors.append(f"{field} must be a string")
    for field in ("arguments", "paths", "disallowed-tools"):
        if field in metadata and not _string_list(metadata[field]):
            errors.append(f"{field} must be a string or list of strings")
    for field in ("disable-model-invocation", "user-invocable", "background"):
        if field in metadata and not _code_boolean(metadata[field]):
            errors.append(f"{field} must be a Claude Code boolean value")
    for field, values in (("effort", {"low", "medium", "high", "xhigh", "max"}), ("context", {"fork"}), ("shell", {"bash", "powershell"})):
        if field in metadata and (not isinstance(metadata[field], str) or metadata[field] not in values):
            errors.append(f"{field} must be one of {', '.join(sorted(values))}")
    if "hooks" in metadata and not isinstance(metadata["hooks"], dict):
        errors.append("hooks must be a mapping")
    return errors
