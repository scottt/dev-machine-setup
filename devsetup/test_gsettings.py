import unittest

from .gsettings import gvariant_loads

# https://developer.gnome.org/glib/stable/gvariant-text.html
TEST_DATA = [
    ('nothing', None),
    ('@ms nothing', None),
    ('true', True),
    ('false', False),
    ('@a{ss} {}', {}),
    ('@ai []', []),
    ("['a', 'b']", ['a', 'b']),
    ("{'a': 'b'}", {'a': 'b'}),
]

class TestGVariant(unittest.TestCase):
    def tests(self):
        for (i, expected) in TEST_DATA:
            self.assertEqual(gvariant_loads(i), expected)

if __name__ == '__main__':
    unittest.main()
