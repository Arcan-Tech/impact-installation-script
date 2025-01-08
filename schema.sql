create table if not exists public.impact_user
(
    id       bigserial
        primary key,
    username varchar(255) not null
        unique,
    password varchar(255) not null,
    email    varchar(255) not null
        unique
);


create table if not exists public.tenant
(
    id          bigserial
        primary key,
    name        varchar(255) not null,
    description text,
    owner       bigint       not null
        constraint fk_owner
            references public.impact_user,
    join_code   varchar(100) default NULL::character varying
);


create table if not exists public.tenant_user
(
    user_id   bigint not null
        constraint fk_user
            references public.impact_user
            on delete cascade,
    tenant_id bigint
        constraint fk_tenant
            references public.tenant
);


create table if not exists public.project
(
    id          bigserial
        primary key,
    name        varchar(255) not null,
    description text,
    owner_id    bigint       not null
        constraint fk_owner_id
            references public.impact_user
);


create table if not exists public.access_credential
(
    id               bigserial
        primary key,
    name             varchar(255) not null,
    description      text,
    provider         varchar(255) not null,
    vcs_type         varchar(255) not null,
    credentials_json json         not null,
    project_id       bigint       not null
        constraint fk_project_id
            references public.project
);


create table if not exists public.repository
(
    id            bigserial
        primary key,
    name          varchar(255) not null,
    org           varchar(255),
    remote_url    varchar(255),
    volume_path   varchar(255),
    credential_id bigint
        constraint fk_credential_id
            references public.access_credential
            on delete set null,
    project_id    bigint       not null
        constraint fk_project_id
            references public.project
);


create table if not exists public.project_repository
(
    project_id    bigint not null
        constraint fk_project_id
            references public.project
            on delete cascade,
    repository_id bigint not null
        constraint fk_repository_id
            references public.repository
            on delete cascade,
    primary key (project_id, repository_id)
);


create table if not exists public.tenant_project
(
    tenant_id  bigint not null
        constraint fk_tenant_id
            references public.tenant
            on delete cascade,
    project_id bigint not null
        constraint fk_project_id
            references public.project
            on delete cascade,
    primary key (tenant_id, project_id)
);


create table if not exists public.branches
(
    id            bigserial
        primary key,
    branch        varchar not null,
    repository_id bigint  not null
        constraint fk_repository_id
            references public.repository
            on delete cascade
);


create table if not exists public.analysis_run_header
(
    id            bigserial  not null
        constraint analysis_run_pkey
            primary key,
    creation_date timestamp default now(),
    created_by    bigint                                                     not null
        constraint fk_user_id
            references public.impact_user
            on delete cascade,
    project_id    bigint                                                     not null
        constraint fk_project_id
            references public.project
            on delete cascade,
    status        varchar
);


create table if not exists public.trained_model
(
    id              bigserial
        primary key,
    model_blob      bytea,
    encoder_blob    bytea,
    analysis_header bigint
        constraint analysis_header___fk
            references public.analysis_run_header
);


create table if not exists public.training_run
(
    id                   bigserial
        primary key,
    start_date           timestamp    not null,
    status               varchar(255) not null,
    last_analysed_commit varchar(50),
    last_analysed_window integer,
    duration             bigint,
    trained_model_id     bigint       not null
        constraint fk_trained_model_id
            references public.trained_model
            on delete cascade,
    end_date             timestamp
);


create table if not exists public.trained_model_branch
(
    id               bigserial
        primary key,
    branch_id        bigint not null
        constraint fk_branch_id
            references public.branches
            on delete cascade,
    trained_model_id bigint not null
        constraint fk_trained_model_id
            references public.trained_model
            on delete cascade
);


create table if not exists public.repo_miners
(
    id           serial
        primary key,
    project_id   varchar(255) not null
        unique,
    start_mining timestamp,
    end_mining   timestamp,
    duration     bigint,
    status       varchar(255),
    opts         bytea
);


create table if not exists public.projects
(
    id     text not null
        primary key,
    name   text not null,
    branch text not null,
    source text not null,
    state  bytea
);


create table if not exists public.files
(
    id         serial
        primary key,
    value      text not null,
    project_id text
        references public.repo_miners (project_id),
    unique (value, project_id)
);


create table if not exists public.jobs
(
    id         serial
        primary key,
    project_id text
        references public.repo_miners (project_id),
    status     text      not null
        constraint jobs_status_check
            check (status = ANY
                   (ARRAY ['initialized'::text, 'running'::text, 'completed'::text, 'failed'::text, 'up_to_date'::text])),
    start_date timestamp not null,
    end_date   timestamp
);


create table if not exists public.datasets_v1
(
    id          serial primary key, -- To use timescale primary key must be removed, at the moment doing so break the training step

    f1          text    not null,
    f2          text    not null,
    is_cochange integer not null
        constraint datasets_v1_is_cochange_check
            check (is_cochange = ANY (ARRAY [0, 1])),
    project_id  text    not null
        references public.repo_miners (project_id),
    windex      integer not null
        constraint datasets_v1_windex_check
            check (windex > 0),
    recency     integer
        constraint datasets_v1_recency_check
            check (recency > 0),
    author      text    not null
);


create table if not exists public.shared_states
(
    id         serial
        primary key,
    project_id text  not null
        unique,
    data       bytea not null
);


create table if not exists public.analysis_run_detail
(
    id         bigserial
        constraint analysis_run_detail_pk
            primary key,
    type       varchar not null,
    status     varchar not null,
    start_date timestamp,
    end_date   timestamp,
    header     bigint  not null
        constraint analysis_run_header___fk
            references public.analysis_run_header
);

CREATE TABLE diffs_v1 (
    parent_sha CHAR(40) NOT NULL,
    child_sha CHAR(40) NOT NULL,
    old_file TEXT NOT NULL,
    new_file TEXT NOT NULL,
    old_lines INTEGER NOT NULL,
    new_lines INTEGER NOT NULL,
    old_author VARCHAR(255) NOT NULL,
    new_author VARCHAR(255) NOT NULL,
    "when" TIMESTAMP NOT NULL
);

-- SELECT create_hypertable('public.datasets_v1', 'windex', chunk_time_interval => 1);

INSERT INTO public.impact_user (id, username, password, email)
VALUES (1, 'dev', '$2a$10$D3HgetPAUcKQosjmeP8C3OsvV65xVwgZEYlj6JmMmsz.Do.1uiC3q', '');

