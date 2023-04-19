<?php
namespace DockerStack;

# A simplistic one-page app to administer docker-stack
class AdminInterface
{
    public static function display()
    {
        echo self::getHead();
        echo self::getBodyStart();
        echo self::getTable('supportedProjectsDataSource', 'Installed Projects', ['Project URL'], 'supportedProjectsColumnRenderer');
        echo self::getTable('containersStatusDataSource', 'Containers Status', ['Container', 'Status'], 'containersStatusColumnRenderer');
        echo self::getBodyEnd();
    }

    public static function getTable($datasource, $heading, $columnNames, $columnRenderer = '')
    {
        return "
        <h1>$heading</h1>
        <table id='$datasource' class='table table-striped table-sm'>
            <thead>
            <tr>".
            "<th>" . implode('</th><th>', $columnNames) . "</th>" .
            "</tr>
            </thead>
        </table>
        <script>
        $(document).ready(function () {
            $('#$datasource').DataTable({
                paging: false,
                ordering: false,
                searching: false,
                info: false,
                ajax: './?$datasource',
                " . ($columnRenderer ? 'columns: ' . self::$columnRenderer() : '') ."
            });
        });
        $(document).ready(function () {
            setInterval(function(){
                $('#$datasource').DataTable().ajax.reload();
            }, 5000);
        });
        </script>";
    }

    public static function getHead(): string
    {
        return '<!doctype html>
            <html lang="en">
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
                <script src="https://code.jquery.com/jquery-3.5.1.js"crossorigin="anonymous"></script>
                <script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js" crossorigin="anonymous"></script>
                <script src="https://cdn.jsdelivr.net/npm/popper.js@1.12.9/dist/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
                <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
            
                <title>Docker-Stack Admin Interface</title>
            </head>
            ';
    }

    public static function getBodyStart(): string
    {
        return '<body>
            <div class="container">
            ';
    }
    public static function getBodyEnd(): string
    {
        return '</div>
          </body>
        </html>';
    }

    public static function supportedProjectsDataSource(): string
    {
        $returnProjects = [];
        $projectBaseDir = '..' . DIRECTORY_SEPARATOR .  '..';
        $projects = scandir($projectBaseDir);
        foreach ($projects as $project) {
            if ('docker-stack-ui.loc' == $project ||
                !preg_match('/^.+\.(local|loc|localhost|test)$/', $project)) {
                continue;
            }
            $returnProjects[] = (object) ['project-url' => $project];
        }
        return json_encode(['data' => $returnProjects]);
    }

    public static function supportedProjectsColumnRenderer()
    {
        return
            "[
                { 
                  data: 'project-url',
                  render: function (data, type) {if (type === 'display') {return '<a target=_blank href=https://' + data + '>' + data + '</a>';} return data;}
                }
            ]";
    }

    public static function getAvailableContainerNames()
    {
        exec("../../bin/docker-compose config --services | sort", $availableContainers);
        return $availableContainers;
    }
    public static function getRunningContainerNames()
    {
       exec("../../bin/docker-compose ps | grep  ' Up ' | awk '{print $1}'", $runningContainers);
       for ($index=0; $index < count($runningContainers); $index++) {
           $runningContainers[$index] = preg_replace('/docker_(.*)_1/', '$1', $runningContainers[$index]);
       }

       return $runningContainers;
    }

    public static function containersStatusDataSource()
    {
        $availableContainers = self::getAvailableContainerNames();
        $runningContainers = self::getRunningContainerNames();
        $returnData = [];
        foreach ($availableContainers as $availableContainer) {
            $returnData[] = (object) [
                    'container' => $availableContainer,
                    'status' => in_array($availableContainer, $runningContainers) ? 'Up' : 'Down'
            ];
        }

        return json_encode(['data' => $returnData]);
    }

    public static function containersStatusColumnRenderer ()
    {
        return
            "[
                {
                    data: 'container',
                },
                { 
                  data: 'status',
                  render: function (data, type) {if (type === 'display') { if (data == 'Up') { return '<button type=button class=\'btn btn-success btn-sm\'>Up</button>';} else { return '<button type=button class=\'btn btn-danger btn-sm\'>Down</button>';} } return data;}
                }
            ]";
    }
}

if (!$_REQUEST ||
    !($method = array_keys($_REQUEST)[0]) ||
    !str_contains($method, 'DataSource') ||
    !method_exists(\DockerStack\AdminInterface::class, $method )) {
    \DockerStack\AdminInterface::display();
} else {
    echo \DockerStack\AdminInterface::$method();
}
