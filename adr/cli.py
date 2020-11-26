import click
import click_logger
from environs import Env

env = Env()
env.read_env()  # read .env file, if it exists


@click.command()
@click_logger.log_level()
@click.option(
    "--input-queue",
    "-i",
    required=True,
    type=str,
    envvar="ADR_QUEUE",
    help="The name of the Redis input queue",
)
@click.option(
    "--output-queue",
    "-o",
    required=True,
    type=str,
    envvar="ADR_OUTPUT_QUEUE",
    help="The name of the Redis output queue",
)
@click.option(
    "--audit-queue",
    required=True,
    default="AUDIT",
    type=str,
    envvar="AUDIT_QUEUE",
    help="The name of the Redis queue for the audit logs",
)
@click.option(
    "--redis-url",
    "-r",
    default="redis://localhost/0",
    type=str,
    show_default=True,
    envvar="REDIS_URL",
    help="The address of the Redis server",
)
@click.option(
    "--environment",
    default="DEV",
    type=str,
    show_default=True,
    envvar="ENVIRONMENT",
    help="Environment we're running in (DEV / PROD / ...)",
)
def cli(
    log_level: str,
    input_queue: str,
    output_queue: str,
    audit_queue: str,
    redis_url: str,
    environment: str
):
    """
    Main entrypoint for execution

    Args:
        log_level:
        input_queue:
        output_queue:
        audit_queue:
        redis_url:
        environment:
    """
    import adr
    from .adr_main import main
    from click_logger.apm import create_apm_client
    from streams import Stream
    from streams.types import QueueConfig
    import redis

    is_debug = environment.lower() not in ("prod", "dev", "notprod")
    label_map = {"kafka_uid": "load.kafka_event_id", "load_number": "load.load_num"}
    apm_client = create_apm_client(
        "adr",
        adr.__version__,
        environment,
        is_debug,
        label_map,
    )

    redis_client = redis.Redis.from_url(redis_url)
    redis_options = redis_client.connection_pool.connection_kwargs.copy()
    redis_host = redis_options.pop("host")  # NOQA
    redis_port = redis_options.pop("port")  # NOQA
    if redis_url.startswith("rediss://"):
        redis_options["ssl"] = True

    click_logger.config(
        log_level=log_level,
        client=redis_client,
        version=adr.__version__,
        app_name="adr",
        queue_name=audit_queue,
        extract_keys=None,  # TODO can we really not add anything to extract_keys?
    )

    input_q = QueueConfig(
        queue_name=input_queue,
        client=redis_client,
    )
    output_q = QueueConfig(
        queue_name=output_queue,
        client=redis_client,
    )
    stream = Stream(
        apm_client=apm_client,
        input_queue=input_q,
        output_queue=output_q,
        processing_func=main,
        fail_silently=False,
    )

    stream.queue_func_queue()


if __name__ == "__main__":
    cli()
