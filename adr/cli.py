import click
import click_config_file
from environs import Env

env = Env()
env.read_env()  # read .env file, if it exists
provider = click_config_file.configobj_provider(section="adr", unrepr=False)


@click.group()
def cli():
    """
    Manage Architectural Decision Records
    """
    pass


@cli.command()
@click.option(
    "--directory",
    "-d",
    default="./doc/adr",
    type=click.Path(file_okay=False, dir_okay=True, writable=True, resolve_path=True),
)
@click.option("--template", "-t", type=click.Path(dir_okay=False, resolve_path=True))
@click.pass_context
@click_config_file.configuration_option(
    provider=provider, cmd_name="adr", config_file_name=".adr.cfg"
)
def init(ctx, directory: str, template: str):
    """
    Initializes the directory of architecture decision records:

        * creates a subdirectory of the current working directory

        * creates the first ADR in that subdirectory, recording the decision to record architectural decisions with ADRs.

    If the DIRECTORY is not given, the ADRs are stored in the directory `doc/adr`.
    """
    # from pathlib import Path
    #
    # config_file_path = Path()
    # if Path()
    print(ctx.parent.__dict__)


if __name__ == "__main__":
    cli()
