pipeline {
  agent {
    node {
      label 'nodejs'
    }

  }
  stages {
    stage('checkout code') {
      steps {
        git(url: 'https://github.com/devlopersabbir/template', branch: 'main')
      }
    }

  }
}