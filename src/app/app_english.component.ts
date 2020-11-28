import { Component } from '@angular/core';
import { HttpService } from './http.service';
import { RecognizedAnswer } from './recognizedAnswer';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
     
@Component({
    selector: 'english-trainer-app',
    template: `
                <section class='intro'>
                    <div class="container">
                        <div class="panel">
                            <div class="form-inline">
                            <div class="title">Welcome buddy! Please tell me something about you</div> 
                                <div class="form-group">
                                    <div class="col-md-8"></div>
                                        <input class="form-control" [(ngModel)]="url" placeholder = "Audio link" />
                                    </div>
                                    <div class="col-md-8">
                                    <div class="form-group">
                                        <div class="col-md-offset-2 col-md-8">
                                            <button class="btn btn-default" (click)="recognize(url, channelsCount)">Evaluate</button>
                                        </div>
                                        <br>
                                        <div *ngIf="running" class="progress-ring"></div> 
                                    </div>
                                </div>
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
    constructor(private sanitizer: DomSanitizer, private httpService: HttpService) { }
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

  async recognize(url, channelsCount) {
        this.running = true;
        channelsCount = "1";
        this.done = false;
        this.emotions = true;
        url = "https://www.dropbox.com/s/p6fo6d9ldgxapje/1ch.wav?dl=1";
        this.twoChannels = channelsCount == "2";
        this.recognizedAnswer = await this.httpService.recognize(url, channelsCount, this.emotions);
        console.log(this.recognizedAnswer);
        this.calc_text_params();
        this.find_phrases();
    
        this.done = true;
        this.running = false;
    }
  
  calc_text_params() {
    this.learnerAccent = 0;
    let phrasesCount = 0;
    this.commonWordsCount = 0;
    this.differentWordsCount = 0;

    let words = [];
      for (let item of this.recognizedAnswer.AudioDialogDescriptor.Phrases) {
        if (item.AuthorId == "Client") {
          this.learnerAccent += Number(item.Confidence);
          phrasesCount++;
          let newArr = item.Text.split(' ');
          for (let i of newArr) {
            words.push(i);
          }
        }
    }
    
    this.learnerText = words.join(" ");

    this.learnerAccent /= phrasesCount;
    this.commonWordsCount = words.length;
    this.differentWordsCount = new Set(words).size;
    }

    find_phrases() {
        let dstCorrectArr = ["никакого", "не"];
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
          });

            dstCorrectArr.forEach(im => {
                let foundCorrectPhrase = false;
                let phrase = im.toLowerCase().trim();
                this.recognizedAnswer.AudioDialogDescriptor.Phrases.forEach(element => {
                    if (element.Text.toLowerCase().includes(phrase)) {
                      foundCorrectPhrase = true;
                      if (element.AuthorId == 'Client') {
                        this.usedComplexConstructions++;
                      }
                    }
                });
                if (!foundCorrectPhrase) {
                    this.notFoundCorrectPhrases.push(phrase);
                    this.correctNotFoundExists = true;

                }
            });
    }

    highlightPhrase(text) { 
        return this.sanitizer.bypassSecurityTrustHtml(text);
    }

    showConfidence(conf) {
        return parseFloat(conf).toFixed(2)
    }
}
