CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS schema_migrations(version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS users(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), email text NOT NULL UNIQUE, password_hash text NOT NULL,
 display_name text NOT NULL, timezone text NOT NULL DEFAULT 'UTC', created_at timestamptz NOT NULL DEFAULT now(),
 CHECK(email=lower(email)));
CREATE TABLE IF NOT EXISTS auth_sessions(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,token_hash text NOT NULL UNIQUE,csrf_token text NOT NULL,expires_at timestamptz NOT NULL,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS user_preferences(user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,quiet_mode boolean NOT NULL DEFAULT false,reduced_motion boolean NOT NULL DEFAULT false);
CREATE TABLE IF NOT EXISTS projects(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),name text NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(user_id,id));
CREATE TABLE IF NOT EXISTS tasks(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),project_id uuid,parent_task_id uuid,title text NOT NULL,status text NOT NULL DEFAULT 'planned' CHECK(status IN('planned','in_progress','postponed','completed','abandoned')),estimated_minutes integer CHECK(estimated_minutes>0),due_at timestamptz,created_at timestamptz NOT NULL DEFAULT now(),first_started_at timestamptz,completed_at timestamptz,version integer NOT NULL DEFAULT 1,UNIQUE(user_id,id),FOREIGN KEY(user_id,project_id) REFERENCES projects(user_id,id),FOREIGN KEY(user_id,parent_task_id) REFERENCES tasks(user_id,id),CHECK(parent_task_id IS DISTINCT FROM id));
CREATE TABLE IF NOT EXISTS task_events(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),task_id uuid NOT NULL,event_type text NOT NULL,old_status text,new_status text,occurred_at timestamptz NOT NULL DEFAULT now(),FOREIGN KEY(user_id,task_id) REFERENCES tasks(user_id,id));
CREATE TABLE IF NOT EXISTS daily_plans(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),plan_date date NOT NULL,timezone text NOT NULL,revision integer NOT NULL,frozen_at timestamptz,created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(user_id,id),UNIQUE(user_id,plan_date,revision));
CREATE TABLE IF NOT EXISTS plan_tasks(user_id uuid NOT NULL REFERENCES users(id),plan_id uuid NOT NULL,task_id uuid NOT NULL,position integer NOT NULL,planned_minutes integer CHECK(planned_minutes>0),PRIMARY KEY(plan_id,task_id),FOREIGN KEY(user_id,plan_id) REFERENCES daily_plans(user_id,id),FOREIGN KEY(user_id,task_id) REFERENCES tasks(user_id,id));
CREATE OR REPLACE FUNCTION protect_plan_members() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN
 IF EXISTS(SELECT 1 FROM daily_plans WHERE id IN (NEW.plan_id,OLD.plan_id) AND frozen_at IS NOT NULL) THEN RAISE EXCEPTION 'Frozen plan is immutable'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW; END $$;
DROP TRIGGER IF EXISTS frozen_members ON plan_tasks;
CREATE TRIGGER frozen_members BEFORE INSERT OR UPDATE OR DELETE ON plan_tasks FOR EACH ROW EXECUTE FUNCTION protect_plan_members();
CREATE OR REPLACE FUNCTION protect_plan() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN
 IF OLD.frozen_at IS NOT NULL THEN RAISE EXCEPTION 'Frozen plan is immutable'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW; END $$;
DROP TRIGGER IF EXISTS frozen_plan ON daily_plans;
CREATE TRIGGER frozen_plan BEFORE UPDATE OR DELETE ON daily_plans FOR EACH ROW EXECUTE FUNCTION protect_plan();
CREATE TABLE IF NOT EXISTS focus_sessions(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),task_id uuid NOT NULL,planned_seconds integer NOT NULL CHECK(planned_seconds BETWEEN 60 AND 28800),status text NOT NULL CHECK(status IN('active','paused','finished')),started_at timestamptz NOT NULL DEFAULT now(),ended_at timestamptz,start_request_key uuid NOT NULL,UNIQUE(user_id,id),UNIQUE(user_id,start_request_key),FOREIGN KEY(user_id,task_id) REFERENCES tasks(user_id,id),CHECK(ended_at IS NULL OR ended_at>=started_at));
CREATE UNIQUE INDEX IF NOT EXISTS one_unfinished_session ON focus_sessions(user_id) WHERE status IN('active','paused');
CREATE TABLE IF NOT EXISTS work_segments(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),session_id uuid NOT NULL,started_at timestamptz NOT NULL DEFAULT now(),ended_at timestamptz,FOREIGN KEY(user_id,session_id) REFERENCES focus_sessions(user_id,id),CHECK(ended_at IS NULL OR ended_at>=started_at));
CREATE UNIQUE INDEX IF NOT EXISTS one_open_segment ON work_segments(user_id) WHERE ended_at IS NULL;
CREATE TABLE IF NOT EXISTS task_checkpoints(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),task_id uuid NOT NULL,resume_note text NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),FOREIGN KEY(user_id,task_id) REFERENCES tasks(user_id,id));
CREATE TABLE IF NOT EXISTS checkins(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),recorded_at timestamptz NOT NULL DEFAULT now(),focus smallint CHECK(focus BETWEEN 1 AND 5),stress smallint CHECK(stress BETWEEN 1 AND 5),energy smallint CHECK(energy BETWEEN 1 AND 5),note text, CHECK(focus IS NOT NULL OR stress IS NOT NULL OR energy IS NOT NULL));
CREATE TABLE IF NOT EXISTS devices(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),label text NOT NULL,token_hash text NOT NULL UNIQUE,tracking_enabled boolean NOT NULL DEFAULT false,consent_epoch integer NOT NULL DEFAULT 0,expires_at timestamptz NOT NULL DEFAULT now()+interval '30 days',revoked_at timestamptz,created_at timestamptz NOT NULL DEFAULT now(),last_seen_at timestamptz,UNIQUE(user_id,id));
CREATE TABLE IF NOT EXISTS consent_events(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),device_id uuid NOT NULL,granted boolean NOT NULL,epoch integer NOT NULL,policy_version text NOT NULL DEFAULT 'domains-only-v1',effective_at timestamptz NOT NULL DEFAULT now(),FOREIGN KEY(user_id,device_id) REFERENCES devices(user_id,id));
CREATE TABLE IF NOT EXISTS outbox_events(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES users(id),task_event_id uuid REFERENCES task_events(id),event_type text NOT NULL,payload jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),processed_at timestamptz,attempts integer NOT NULL DEFAULT 0);
CREATE INDEX IF NOT EXISTS tasks_owner_status ON tasks(user_id,status);
CREATE INDEX IF NOT EXISTS task_history_time ON task_events(user_id,occurred_at);
CREATE INDEX IF NOT EXISTS checkpoints_latest ON task_checkpoints(user_id,task_id,created_at DESC);
CREATE INDEX IF NOT EXISTS segments_owner_time ON work_segments(user_id,started_at);
CREATE INDEX IF NOT EXISTS checkins_owner_time ON checkins(user_id,recorded_at);
INSERT INTO schema_migrations(version) VALUES('001_core') ON CONFLICT DO NOTHING;
