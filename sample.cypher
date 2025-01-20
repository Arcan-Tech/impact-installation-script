/*CREATE (:Repository {id: 1, remote_id: 100, namespace: 'example_namespace', name: 'example_repo', 
                      full_name: 'example_repo_full', arch_component: 'unknown_component', 
                      http_url: 'http://example.com', ssh_url: 'ssh://example.com', branch: 'main', 
                      last_activity_date: date('2025-01-14'), status: 'active'});

CREATE (:Commit {id: 1, repository: 1, sha: 'abc123', author: 'John Doe', email: 'john@example.com', 
                 when: datetime('2025-01-14T00:00:00'), summary: 'Initial commit'});

CREATE (:File {id: 1, repository: 1, name: 'example_file.js'});

CREATE (:Release {id: 1, repository: 1});

MATCH (r:Repository), (c:Commit)
WHERE r.id = 1 AND c.id = 1
CREATE (c)-[:COMMITTED_TO]->(r);

MATCH (r:Repository), (f:File)
WHERE r.id = 1 AND f.id = 1
CREATE (f)-[:PART_OF]->(r);

MATCH (f:File), (r:Repository)
WHERE f.id = 1 AND r.id = 1
CREATE (f)-[:F2I_ASSOC]->(r);

MATCH (f:File), (r:Repository)
WHERE f.id = 1 AND r.id = 1
CREATE (f)-[:F2ITimeAssoc {sha: 'abc123', issue_id: 'issue001'}]->(r);

MATCH (f1:File), (f2:File), (r:Repository)
WHERE f1.id = 1 AND f2.id = 2 AND r.id = 1
CREATE (f1)-[:F2FAssoc {p: 0.75}]->(f2);

MATCH (r:Repository), (rl:Release)
WHERE r.id = 1 AND rl.id = 1
CREATE (rl)-[:RELEASED_ON]->(r);*/
