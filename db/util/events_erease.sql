truncate table gedi_image_data RESTART IDENTITY;
truncate table gedi_images RESTART IDENTITY;
truncate table gedi_infractions RESTART IDENTITY;
truncate table gedi_events RESTART IDENTITY;
truncate table gedi_lots RESTART IDENTITY;
truncate table gedi_integrations RESTART IDENTITY;
delete from gedi_managed_task_executions where managed_task_id=1;