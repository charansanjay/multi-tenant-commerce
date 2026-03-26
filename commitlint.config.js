export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Type must be one of these
    'type-enum': [
      2,
      'always',
      [
        'feat', // new feature
        'fix', // bug fix
        'chore', // maintenance, tooling, dependencies
        'docs', // documentation only
        'style', // formatting — no logic change
        'refactor', // neither fix nor feature
        'perf', // performance improvement
        'test', // adding or updating tests
        'ci', // CI pipeline changes
        'build', // build system changes
        'revert', // reverting a previous commit
        'breaking-change', // breaking API or DB change
      ],
    ],

    // Optional scopes — if provided must be one of these
    'scope-enum': [
      1, // warn only, not error — scopes are optional
      'always',
      ['admin', 'web', 'super-admin', 'ui', 'types', 'utils', 'config', 'db'],
    ],

    // Casing
    'type-case': [2, 'always', 'lower-case'],
    'scope-case': [2, 'always', 'lower-case'],
    'subject-case': [2, 'always', 'lower-case'],

    // Subject rules
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'type-empty': [2, 'never'],

    // Length limits
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [2, 'always', 100],
    'footer-max-line-length': [2, 'always', 100],
  },
};
