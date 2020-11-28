import { NgModule }      from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule }   from '@angular/forms';
import { AppEnglishComponent } from './app_english.component';
import { HttpClientModule } from '@angular/common/http';

@NgModule({
    imports:      [ BrowserModule, FormsModule, HttpClientModule ],
    declarations: [ AppEnglishComponent ],
    bootstrap:    [ AppEnglishComponent ]
})
export class AppModule { 
     
}