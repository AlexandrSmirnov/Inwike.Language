import {Injectable} from '@angular/core';
import {HttpClient, HttpHeaders} from '@angular/common/http';
import { RecognizedAnswer } from './recognizedAnswer';
  
@Injectable()
export class HttpService{
    
    main_url = 'http://45.101.122.103:5050/api/';

    path = 'GetTaskResult?id=0f9b4870-263a-40b3-a6d3-ed9a89cd762b';
    text_method = 'CreateTask';
    text_with_emotions_method = 'CreateTaskSttAndVoiceFeatures';

    constructor(private http: HttpClient){ }
    
    async delay(ms: number) {
        return new Promise( resolve => setTimeout(resolve, ms) );
    }

    async createTask(link: string, channelsCount: string, emotions: boolean) {
        let data = {
            "file_url" : link
        }

        let method = emotions ? this.text_with_emotions_method : this.text_method;

        return await this.http.post(this.main_url + method + '?apikey=2c7311bd-af34-4085-9e85-14748ea1077d&channelsCount=' + channelsCount + '&useYandex=False', data).toPromise();
    }
    
    async getTaskResult(id:string)
    {
        return this.http.get(this.main_url + 'GetTaskResult?id=' + id).toPromise();
    }

    async recognize(url, channelsCount, emotions) {
        let idData = {
            "id": "id"
        }

        let answerModel : RecognizedAnswer; 
        answerModel = null;
        let createTaskAnswer;
        
        await this.createTask(url, channelsCount, emotions).then((data) => {
            createTaskAnswer = data;
        });

        idData = JSON.parse(createTaskAnswer);
        while (answerModel == null) {
            let idDataY;
            await this.getTaskResult(idData["id"]).then((data:string) => {
                idDataY = JSON.parse(data);
            });
            if (idDataY["Status"] != "Error") {
                answerModel = idDataY;                
            }

            console.log("waiting answer");
            await this.delay(3000);
        };

        let resultModel = new RecognizedAnswer();
        resultModel.AudioDialogDescriptor = answerModel.AudioDialogDescriptor;
        resultModel.FragmentFeatures = answerModel.FragmentFeatures;
        resultModel.Status = answerModel.Status;
        
        if (emotions) {
            if (channelsCount == "1") {
                resultModel.createFeatures("Client");
            } else {
                resultModel.createFeatures("Client");
                resultModel.createFeatures("Operator");
            }
        }
        return resultModel;
    }
}