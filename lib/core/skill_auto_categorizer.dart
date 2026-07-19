import 'models/resume_models.dart';

/// Assigns flat skills to resume categories (Programming Languages, Tools, …).
class SkillAutoCategorizer {
  SkillAutoCategorizer._();

  static const String programmingLanguages = 'Programming Languages';
  static const String frameworks = 'Frameworks';
  static const String tools = 'Tools';
  static const String databases = 'Databases';
  static const String cloudDevOps = 'Cloud & DevOps';
  static const String softSkills = 'Soft Skills';
  static const String other = 'Other';

  /// Preferred display order on the resume / editor.
  static const List<String> categoryOrder = [
    programmingLanguages,
    frameworks,
    tools,
    databases,
    cloudDevOps,
    softSkills,
    other,
  ];

  /// Groups [skills] into named [SkillGroup]s. Unknown skills go to Other.
  static List<SkillGroup> categorize(Iterable<String> skills) {
    final buckets = <String, List<String>>{
      for (final name in categoryOrder) name: <String>[],
    };
    final seen = <String>{};

    for (final raw in skills) {
      final skill = raw.trim();
      if (skill.isEmpty) {
        continue;
      }
      final key = skill.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }
      final category = categoryFor(skill);
      buckets[category]!.add(skill);
    }

    final groups = <SkillGroup>[];
    for (final name in categoryOrder) {
      final items = buckets[name]!;
      if (items.isEmpty) {
        continue;
      }
      items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      groups.add(SkillGroup(heading: name, skills: items));
    }

    if (groups.isEmpty) {
      return const [SkillGroup(heading: '', skills: [])];
    }
    return groups;
  }

  /// Resolves a single skill to a category name.
  static String categoryFor(String skill) {
    final key = skill.trim().toLowerCase();
    if (key.isEmpty) {
      return other;
    }

    final mapped = _lookup[key];
    if (mapped != null) {
      return mapped;
    }

    return _heuristicCategory(key);
  }

  static String _heuristicCategory(String key) {
    if (_softSkillHints.any(key.contains)) {
      return softSkills;
    }
    if (_databaseHints.any(key.contains) || key.endsWith(' db') || key.endsWith('db')) {
      return databases;
    }
    if (_cloudHints.any(key.contains)) {
      return cloudDevOps;
    }
    if (_frameworkHints.any(key.contains) ||
        key.endsWith('.js') ||
        key.endsWith('.ts')) {
      return frameworks;
    }
    if (_languageHints.any(key.contains)) {
      return programmingLanguages;
    }
    if (_toolHints.any(key.contains)) {
      return tools;
    }
    return other;
  }

  static final Map<String, String> _lookup = _buildLookup();

  static Map<String, String> _buildLookup() {
    final map = <String, String>{};

    void add(String category, List<String> skills) {
      for (final skill in skills) {
        map.putIfAbsent(skill.toLowerCase(), () => category);
      }
    }

    add(programmingLanguages, _programmingLanguages);
    add(frameworks, _frameworks);
    add(tools, _tools);
    add(databases, _databases);
    add(cloudDevOps, _cloudDevOps);
    add(softSkills, _softSkills);
    return map;
  }

  static const List<String> _programmingLanguages = [
    'Bash',
    'C',
    'C#',
    'C++',
    'Dart',
    'Elixir',
    'Elm',
    'Erlang',
    'Go',
    'Groovy',
    'Haskell',
    'HTML',
    'CSS',
    'Java',
    'JavaScript',
    'Julia',
    'Kotlin',
    'Lua',
    'MATLAB',
    'Objective-C',
    'OCaml',
    'Perl',
    'PHP',
    'PowerShell',
    'Python',
    'R',
    'Ruby',
    'Rust',
    'Scala',
    'Solidity',
    'SQL',
    'Swift',
    'TypeScript',
    'VBA',
    'VHDL',
    'Verilog',
    'YAML',
  ];

  static const List<String> _frameworks = [
    'Angular',
    'Astro',
    'Bootstrap',
    'Django',
    'Django REST Framework',
    'Ember.js',
    'Entity Framework',
    'Express.js',
    'Flask',
    'Flutter',
    'Gatsby',
    'Hibernate',
    'Hugo',
    'Jest',
    'JUnit',
    'JUnit 5',
    'Keras',
    'Laravel',
    'Next.js',
    'Node.js',
    'Nuxt',
    'Phoenix',
    'PyTorch',
    'Qt',
    'React',
    'React Native',
    'Redux',
    'Robot Framework',
    'Ruby on Rails',
    'Scikit-learn',
    'Spring',
    'Spring Boot',
    'Strapi',
    'Svelte',
    'SvelteKit',
    'SwiftUI',
    'Symfony',
    'Tailwind CSS',
    'TensorFlow',
    'Three.js',
    'UIKit',
    'Vert.x',
    'Vue.js',
    'Xamarin',
    '.NET',
    'ASP.NET',
    'FastAPI',
    'NestJS',
    'Remix',
    'SolidJS',
  ];

  static const List<String> _tools = [
    'Asana',
    'Chrome DevTools',
    'Concur',
    'Figma',
    'Git',
    'GitHub',
    'GitLab',
    'Google Analytics',
    'Gradle',
    'Illustrator',
    'InVision',
    'Jira',
    'Looker',
    'Maven',
    'Microsoft 365',
    'npm',
    'pandas',
    'Photoshop',
    'Postman',
    'Power BI',
    'PySpark',
    'PyTest',
    'QuickBooks Online',
    'Salesforce',
    'SAS',
    'Selenium',
    'Shopify',
    'Sketch',
    'Storybook',
    'Webpack',
    'Wireframing',
    'WordPress',
    'Workday',
    'Xcode',
    'yarn',
    'Zapier',
    'Zendesk',
    'BlackLine',
    'Notion',
    'Slack',
    'Trello',
    'Excel',
    'Tableau',
    'Adobe XD',
    'Canva',
  ];

  static const List<String> _databases = [
    'BigQuery',
    'Cassandra',
    'Couchbase',
    'DynamoDB',
    'Elasticsearch',
    'Firebase',
    'Hive',
    'InfluxDB',
    'MariaDB',
    'MongoDB',
    'MySQL',
    'Oracle DB',
    'PostgreSQL',
    'Redis',
    'Snowflake',
    'Solr',
    'SQLite',
    'Neo4j',
    'Supabase',
    'Realm',
  ];

  static const List<String> _cloudDevOps = [
    'Ansible',
    'Apache Airflow',
    'Apache Kafka',
    'AWS',
    'Azure',
    'Azure DevOps',
    'CI/CD',
    'CircleCI',
    'Cloud Architecture',
    'Databricks',
    'DevOps',
    'Docker',
    'ELK Stack',
    'Fluentd',
    'GitHub Actions',
    'Google Cloud',
    'Grafana',
    'Hadoop',
    'Heroku',
    'IAM',
    'IBM Cloud',
    'Jenkins',
    'K8s',
    'Keycloak',
    'Kubernetes',
    'LDAP',
    'Linux',
    'MLflow',
    'NATS',
    'NGINX',
    'OAuth',
    'OIDC',
    'OpenAPI',
    'OpenShift',
    'Prometheus',
    'Protobuf',
    'Puppet',
    'RabbitMQ',
    'SAML',
    'SecOps',
    'Serverless',
    'SSL/TLS',
    'SSO',
    'Terraform',
    'Traefik',
    'Unix',
    'gRPC',
    'HTTP/REST',
    'SOAP',
    'Microservices',
    'GCP',
    'Helm',
    'ArgoCD',
    'Pulumi',
  ];

  static const List<String> _softSkills = [
    'Agile',
    'Analytical Thinking',
    'Cross-functional Collaboration',
    'Customer Success',
    'Mentoring',
    'Product Management',
    'Project Management',
    'Public Speaking',
    'Requirements Gathering',
    'Scrum',
    'Stakeholder Management',
    'Team Leadership',
    'Technical Writing',
    'User Research',
    'Communication',
    'Leadership',
    'Problem Solving',
    'Time Management',
    'Conflict Resolution',
    'Negotiation',
    'Presentation Skills',
    'Collaboration',
    'Critical Thinking',
    'Adaptability',
    'Creativity',
  ];

  static const List<String> _softSkillHints = [
    'leadership',
    'communication',
    'mentoring',
    'collaboration',
    'stakeholder',
    'public speaking',
    'teamwork',
    'negotiation',
    'presentation',
    'problem solving',
    'time management',
    'critical thinking',
    'adaptability',
    'creativity',
    'empathy',
    'management',
  ];

  static const List<String> _databaseHints = [
    'sql',
    'database',
    'mongodb',
    'postgres',
    'mysql',
    'redis',
    'cassandra',
    'dynamodb',
    'elasticsearch',
    'firestore',
    'snowflake',
    'bigquery',
  ];

  static const List<String> _cloudHints = [
    'aws',
    'azure',
    'gcp',
    'google cloud',
    'kubernetes',
    'docker',
    'terraform',
    'devops',
    'ci/cd',
    'jenkins',
    'cloud',
    'serverless',
    'helm',
    'ansible',
    'prometheus',
    'grafana',
  ];

  static const List<String> _frameworkHints = [
    'framework',
    'react',
    'angular',
    'vue',
    'flutter',
    'django',
    'spring',
    'laravel',
    'rails',
    'express',
    'next.js',
    'nuxt',
    'svelte',
    'bootstrap',
    'tailwind',
    'fastapi',
    'nestjs',
    '.net',
  ];

  static const List<String> _languageHints = [
    'python',
    'javascript',
    'typescript',
    'kotlin',
    'swift',
    'golang',
    'rust',
    'java ',
    'php',
    'ruby',
    'scala',
    'dart',
    'programming language',
  ];

  static const List<String> _toolHints = [
    'git',
    'jira',
    'figma',
    'postman',
    'photoshop',
    'illustrator',
    'excel',
    'tableau',
    'power bi',
    'analytics',
    'webpack',
    'npm',
    'yarn',
    'xcode',
    'android studio',
  ];
}
