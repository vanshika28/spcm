pipeline{
    agent any
    tools {
  terraform 'terraform-11'
    }
    stages{
        stage('Git Checkout'){
            steps{
               git credentialsId: '87315ee5-6b30-40c6-82c6-251a66b18ca3', url: 'https://github.com/vanshika28/spcm'
            }
            
        }
        stage('Terraform Init'){
            steps{
                sh label: '', script: 'terraform init'
            }
            
        }
            
            stage('Terraform Apply'){
            steps{
                sh label: '', script: 'terraform apply --auto-approve'
            }
                
            }
        
    
        }
}
