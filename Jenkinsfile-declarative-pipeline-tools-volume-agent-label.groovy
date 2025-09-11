// Uses Declarative syntax to run commands inside a container.
pipeline {
    agent {
        // you can reference the pod agent by label
        // requires podtemplate setup in CJOC or Controller see casc-k8s-podtemplate.yaml
        label "tools"
    }
    stages {
        stage('Tools') {
            environment {
                JAVA_HOME="/tools/tools-linux/java/jdk-23.0.2"
                PATH="$PATH:$JAVA_HOME/bin"
            }
            steps {
                sh 'java --version'
            }
        }
    }
}
