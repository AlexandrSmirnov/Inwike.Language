import { Component } from '@angular/core';
import { HttpService } from './http.service';
import { RecognizedAnswer } from './recognizedAnswer';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import * as RecordRTC from 'recordrtc';

@Component({
    selector: 'english-trainer-app',
    template: `
                <section class='intro'>
                    <div class="container">
                        <div class="panel">
                            <div class="form-inline">
                            <div class="title">Welcome buddy!</div>
                            <div class="title">Please tell me something about you</div>
                            <div class="form-group">
                            <button (click)="initiateRecording()" class="btn btn-default" *ngIf="!recording" style="cursor: pointer; color: white;"> Start Recording </button>
                            <button (click)="stopRecording()" class="btn btn-danger" *ngIf="recording" style="cursor: pointer;background-color: red;color: white;font-size: 40px;"> Stop Recording </button>
                            <br>
                            <audio controls="" *ngIf="urlblob">
                            <source [src]="sanitizeUrl(urlblob)" type="audio/wav">
                            </audio>
                            </div>
                                <div class="form-group">
                                    <div style="hidden:true" class="col-md-8"></div>
                                    </div>
                                    <div class="col-md-8">
                                    <div class="form-group">
                                        <div *ngIf="urlblob" class="col-md-offset-2 col-md-8">
                                            <button class="btn btn-default" (click)="recognize(url, channelsCount)">Evaluate</button>
                                        </div>
                                        <br>
                                        <div *ngIf="running" class="progress-ring"></div> 
                                    </div>
                                </div>
                            </div>
                            <div *ngIf="done">
                              <p style="align:center">Yep! Your score:</p>
                              <p style="margin-left:50px;align:center;color:orange;font-size:50px">{{showConfidence(finalScore)}}</p>
                            </div>
                        </div>
                    </div> 
                </section>
                <div *ngIf="done">
                    <div class="form-group">
                            <div class="col-md-offset-2 col-md-8">
                              <div><h4 style="color:white">Not bad, let's see your results</h4></div>
                            </div>
                    </div>
                    <section class='container'>
                      <div class="detail" id="iphone_id">
                          <div class="iphone">
                              <div class="dinamic"></div>
                              <div class="iphone-display">
                                <div class="msg">
                                    <div class="item11">
                                          <div class="name-msg1"><b>Trainer</b></div>
                                          <div class="text-msg1">Tell me something!</div>
                                      </div>
                                      <br>
                                    <div class="item2">
                                        <div class="item22">
                                        <div class="name-msg1"><b>Client</b></div>
                                        <div class="text-msg1">
                                            <section class="content" [innerHTML]="this.highlightPhrase(learnerText)">
                                            </section>
                                        </div>
                                        </div>
                                    </div>
                                </div>
                              </div>
                            </div>
                        </div>
                    </section>

                    <section class='container'>
                      <div class="detail">
                          <div class="title">Learner speach details</div>
                          <div class="diferens">
                              <img ng-src="src/assets/123.jpg" alt="">
                              <p>Used complex constructions:</p>
                              <p id='number'>{{usedComplexConstructions}}</p>
                          </div>
                          <div class="diferens">
                              <img ng-src="src/assets/word.png" alt="">
                              <p>Overall words count:</p>
                              <p id='number'>{{commonWordsCount}}</p>
                          </div>
                          <div class="diferens">
                              <img ng-src="src/assets/word.png" alt="">
                              <p>Different words count:</p>
                              <p id='number'>{{differentWordsCount}}</p>
                          </div>
                          <div class="diferens">
                              <img ng-src="src/assets/word.png" alt="">
                              <p>Pauses count:</p>
                              <p id='number'>{{pausesCount}}</p>
                          </div>
                          <div class="diferens">
                              <img ng-src="src/assets/level.png" alt="">
                              <p>Pronounce level:</p>
                              <p id='number'>{{showConfidence(learnerAccent)}}</p>
                          </div>
                      </div>
                  </section>
                  <!--detail voice 1-->
                  <section class='container'>
                      <div class="detail">
                          <div class="title">Learner voice details</div>
                          <div class="detail-items">
                              <div class="detail-voice">
                                  <div class="diferens">
                                      <p>Sex:</p>
                                      <p id='number'>{{this.recognizedAnswer.Client.Temp.Feature == "Мужской" ? "Man" : "Woman"}}</p>
                                  </div>
                                  <div class="diferens">
                                      <p>Age:</p>
                                      <p id='number'>{{this.recognizedAnswer.Client.Mood.Feature == "Взрослый" ? "Adult" : "Old"}}</p>
                                  </div>
                                  <div class="diferens">
                                      <p>Tempo:</p>
                                      <p id='number'>{{this.recognizedAnswer.Client.Temp.Feature == "Быстрый темп" ? "Fast" : "Normal"}}</p>
                                  </div>
                                  <div class="diferens">
                                      <p>Mood:</p>
                                      <p id='number'>{{this.recognizedAnswer.Client.Mood.Feature == "Спокоен" ? "Positive" : "Normal or Sad"}}</p>
                                  </div>
                              </div>
                          </div>
                          
                      </div>
                  </section>
                </div>
                `,
    providers: [HttpService ],
    styleUrls: ['./app.component.css']
})
    
export class AppEnglishComponent{
    constructor(private sanitizer: DomSanitizer, private httpService: HttpService) {}
    url: string;
    channelsCount: string;
    ht: SafeHtml;
    correct: string;
    notcorrect: string;
    notFoundCorrectPhrases: string [];
    recognizedAnswer: RecognizedAnswer = new RecognizedAnswer();
    done: boolean = false;
    running: boolean = false;
    correctNotFoundExists: boolean = false;
    emotions: boolean = false;
    twoChannels: boolean = false;
    learnerText: string;
  learnerAccent: number = 0;
  commonWordsCount: number = 0;
  differentWordsCount: number = 0;
  usedComplexConstructions: number = 0;
  pausesCount: number = 0;
  finalScore: number = 0;
  record;
  recording = false;
  urlblob;

  async recognize(url, channelsCount) {
        this.running = true;
        channelsCount = "1";
        this.done = false;
        this.emotions = true;
        url = "https://www.dropbox.com/s/tideenk0biq1mq0/2.mp3?dl=1";
        this.twoChannels = channelsCount == "2";
        this.recognizedAnswer = await this.httpService.recognize(url, channelsCount, this.emotions);
        console.log(this.recognizedAnswer);
        this.calc_text_params();
        this.find_phrases();
        this.calc_final_score();
    
        this.done = true;
        this.running = false;
    }
  
  calc_text_params() {
    this.learnerAccent = 0;
    let phrasesCount = 0;
    this.commonWordsCount = 0;
    this.differentWordsCount = 0;
    this.pausesCount = 0;
    
    let lengthPhrases = this.recognizedAnswer.AudioDialogDescriptor.Phrases.length;
    let words = [];
      for (let j = 0; j < lengthPhrases; j++) {
        let item = this.recognizedAnswer.AudioDialogDescriptor.Phrases[j];
        if (item.AuthorId == "Client") {
          this.learnerAccent += Number(item.Confidence);
          phrasesCount++;
          let newArr = item.Text.split(' ');
          for (let i of newArr) {
            words.push(i);
          }
          if (j < lengthPhrases - 1) {
            if (this.recognizedAnswer.AudioDialogDescriptor.Phrases[j + 1].StartingSecond
               - this.recognizedAnswer.AudioDialogDescriptor.Phrases[j].EndingSecond > 1) {
              this.pausesCount++;
            }
          }
        }
    }
    
    this.learnerText = words.join(" ");

    this.learnerAccent /= phrasesCount;
    this.commonWordsCount = words.length;
    this.differentWordsCount = new Set(words).size;
    }

    find_phrases() {
        let dstCorrectArr = ["used to", "proficiency", "of great importance", "value", "i d like to", "i d love to", "i find it", "looking forward to", "opportunity", "possibility", "i am going to", "i am planning to", "i would like to", "it seems", "sightseeing", "i am well traveled", "i ve been to", "i have not been to", "i have seen", "i would like to", "i am good at", "it feels", "i used to", "i am used to", "i d be happy to", "i have been", "i find it", "whenever i have time", "well", "so", "like", "again", "uhm"];
        let dstNotCorrectArr = this.notcorrect != null ? this.notcorrect.split(",") : [];
        this.notFoundCorrectPhrases = [];
        this.usedComplexConstructions = 0;

        this.recognizedAnswer.AudioDialogDescriptor.Phrases.forEach(element => {
            dstCorrectArr.forEach(im => {
                let phrase = im.toLowerCase().trim().trimLeft();
                let re = new RegExp(phrase, "g");
                element.Text = element.Text.toLowerCase().replace(re, '<span style=color:green><b>' + phrase + '</b></span>');
            });

            dstNotCorrectArr.forEach(im => {
                let phrase = im.toLowerCase().trim().trimLeft();
                let re = new RegExp(phrase, "g");
                element.Text = element.Text.toLowerCase().replace(re, '<span style=color:red><b>' + phrase + '</b></span>');
            });
          });

          dstCorrectArr.forEach(im => {
            let phrase = im.toLowerCase().trim().trimLeft();
            let re = new RegExp(phrase, "g");
            this.learnerText = this.learnerText.toLowerCase().replace(re, '<span style=color:green><b>' + phrase + '</b></span>');
            if (this.learnerText.toLowerCase().includes(phrase)) {
              this.usedComplexConstructions++;
            }
        });

            dstCorrectArr.forEach(im => {
                let foundCorrectPhrase = false;
                let phrase = im.toLowerCase().trim();
                this.recognizedAnswer.AudioDialogDescriptor.Phrases.forEach(element => {
                    if (element.Text.toLowerCase().includes(phrase)) {
                      foundCorrectPhrase = true;
                    }
                });
                if (!foundCorrectPhrase) {
                    this.notFoundCorrectPhrases.push(phrase);
                    this.correctNotFoundExists = true;

                }
            });
    }

    calc_final_score() {
      this.finalScore = 0;
      let pauseCoeff = this.pausesCount / 100;
      if (pauseCoeff > 0.1) {
        pauseCoeff = 0.1 
      }

      let usedComplexConstructionsCoeff = this.usedComplexConstructions / 20;
      if (usedComplexConstructionsCoeff > 0.15) {
        usedComplexConstructionsCoeff = 0.15 
      }
      
      this.finalScore = this.differentWordsCount / this.commonWordsCount * 0.2 + this.learnerAccent * 0.8;
       + usedComplexConstructionsCoeff - pauseCoeff;

      if (this.finalScore > 1.0) {
        this.finalScore = 1.0;
      }

      this.finalScore *= 100;
    }

    highlightPhrase(text) { 
        return this.sanitizer.bypassSecurityTrustHtml(text);
    }

    showConfidence(conf) {
        return parseFloat(conf).toFixed(2)
    }

    sanitizeUrl(aurl: string) {
      this.url = aurl;
      return this.sanitizer.bypassSecurityTrustUrl(aurl);
    }

    initiateRecording() {
      this.urlblob = null;
      this.recording = true;
      let mediaConstraints = {
      video: false,
      audio: true
      };
      navigator.mediaDevices.getUserMedia(mediaConstraints).then(this.successCallback.bind(this), this.errorCallback.bind(this));
    }

    successCallback(stream) {
        let options = {
          mimeType: "audio/wav",
          numberOfAudioChannels: 1,
          sampleRate: 8000,
        };
        //Start Actuall Recording
        let StereoAudioRecorder = RecordRTC.StereoAudioRecorder;
        this.record = new StereoAudioRecorder(stream, options);
        this.record.record();
    }
    
    errorCallback(error) {
      console.log('Can not play audio in your browser');
    }

    stopRecording() {
        this.recording = false;
        this.record.stop(this.processRecording.bind(this));
    }

    /**
    * processRecording Do what ever you want with blob
    * @param  {any} blob Blog
    */
    processRecording(blob) {
      this.urlblob = URL.createObjectURL(blob);
      console.log("blob", blob);
      console.log("urlblob", this.urlblob);
    }
}
