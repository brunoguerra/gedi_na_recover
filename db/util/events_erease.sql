truncate table gedi_image_data;
truncate table gedi_images;
truncate table gedi_infractions;
truncate table gedi_events;
truncate table gedi_lots;
truncate table gedi_integrations;
delete from gedi_managed_task_executions where managed_task_id=1;