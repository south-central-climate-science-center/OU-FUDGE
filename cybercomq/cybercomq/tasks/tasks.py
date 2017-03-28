from celery.task import task
from dockertask import docker_task
from subprocess import call,STDOUT
import requests
import os

#Default base directory 
basedir="/data/static/"


#Example task
@task()
def add(x, y):
    """ Example task that adds two numbers or strings
        args: x and y
        return addition or concatination of strings
    """
    result = x + y
    return result

@task()
def add_usingR(x, y):
    """
        Generic task to batch submit to R
		args: x and y
        return result_url 
    """
    task_id = str(add_usingR.request.id)
    resultDir = setup_result_directory(task_id)
    host_data_resultDir = "/data/static/someapp_tasks/{0}".format(task_id)
    runfile = "/data/static/add_usingR.R"	
    #Run R Script in an R container
    docker_opts = "--user docker -v {0}:/home/docker/input:z -v {1}:/home/docker/output -w /home/docker/input " \
	   .format(basedir,host_data_resultDir)
	#This assumes unique output folder for each task id
    docker_cmd ="R CMD BATCH --no-save --no-restore '--args {0} {1}' {2} {3}{4}".format(x,y,runfile,resultDir,"/output.Rout")
    result = docker_task(docker_name="rocker/r-base",docker_opts=docker_opts,docker_command=docker_cmd,id=task_id)
	#/data/static/ is viewable client-side
	#This maps to /opt/someapp/data/static/someapp_tasks/{{task_id}}/
    result_url ="http://{0}/someapp_tasks/{1}/output.Rout".format(result['host'],result['task_id'])
	return result_url
	
	
def setup_result_directory(task_id):
    resultDir = os.path.join(basedir, 'someapp_tasks/', task_id)
    os.makedirs(resultDir)
    os.makedirs("{0}/input".format(resultDir))
    os.makedirs("{0}/output".format(resultDir))
    return resultDir 