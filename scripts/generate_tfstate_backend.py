from jinja2 import Environment, FileSystemLoader
import os

def main():
    env = Environment(loader=FileSystemLoader('terraform'))
    template = env.get_template('backend.tf.j2')

    context = {
        'aws_role_arn': os.environ.get('AWS_ROLE_ARN'),
        'aws_oidc_token': os.environ.get('AWS_OIDC_TOKEN'),
        'tfstate_bucket': os.environ.get('TFSTATE_BUCKET'),
        'tfstate_bucket_region': os.environ.get('TFSTATE_BUCKET_REGION'),
        'root_domain': os.environ.get('CLOUDFLARE_DOMAIN'),
        'app_shortname': os.environ.get('TF_VAR_APP_SHORTNAME'),
        'org_shortname': os.environ.get('TF_VAR_ORG_SHORTNAME'),
        'env_slug': os.environ.get('TF_VAR_ENV_SLUG')
    }

    rendered_content = template.render(context)

    with open('terraform/backend.tf', 'w') as f:
        f.write(rendered_content)

if __name__ == "__main__":
    main()