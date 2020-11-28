export class RecognizedAnswer{
  Status: string;
  AudioDialogDescriptor: AudioDialogDescriptor;
  FragmentFeatures: Object[];
  Operator: Speacker;
  Client: Speacker;

  createFeatures(owner: string) {
    if (owner == "Client") {
      this.Client = new Speacker();
      this.Client.Sex = this.getAggregateFeatureFromJson('sex', owner);
      this.Client.Age = this.getAggregateFeatureFromJson('age', owner);
      this.Client.Mood = this.getAggregateFeatureFromJson('mood', owner);
      this.Client.Temp = this.getAggregateFeatureFromJson('temp', owner);
    } else {
      this.Operator = new Speacker();
      this.Operator.Sex = this.getAggregateFeatureFromJson('sex', owner);
      this.Operator.Age = this.getAggregateFeatureFromJson('age', owner);
      this.Operator.Mood = this.getAggregateFeatureFromJson('mood', owner);
      this.Operator.Temp = this.getAggregateFeatureFromJson('temp', owner);
    }
  }

  getAggregateFeatureFromJson(feature, required_owner) {
    let sumPos = 0;
    let sumNeg = 0;

    let fragmentsCount = 0;
    for (let item of this.FragmentFeatures) {
      if ('error' in item["Features"]) {
        continue;
      }

      let ans = item["Features"]["classifiedanswer"];
      if (ans["status"] == "no_speech") {
        continue;
      }
      
      let owner = item["Owner"];
      if (owner != required_owner) {
        continue;
      }

      fragmentsCount += 1;
      let conf = ans[feature]["recognition_result"]["confidence"];

      if (feature == 'sex') {
        if (ans[feature]["recognition_result"]["answer"] == 'male') {
          sumPos += Number(conf);
        }
        else {
          sumNeg += Number(conf);
        }
      }

      if (feature == 'age') {
        if (ans[feature]["recognition_result"]["answer"] == 'adult') {
          sumPos += Number(conf);
        }
        else {
          sumNeg += Number(conf);
        }
      }

      if (feature == 'mood') {
        if (ans[feature]["recognition_result"]["answer"] == 'normal or happy') {
          sumPos += Number(conf);
        }
        else {
          sumNeg += Number(conf);
        }
      }

      if (feature == 'temp') {
        if (ans[feature]["recognition_result"]["answer"] == 'fast') {
          sumPos += Number(conf);
        }
        else {
          sumNeg += Number(conf);
        }
      }
    }

    if (fragmentsCount == 0) {
      return { "Feature": "Error", "Confidence": 0 };
    }
    
    if (feature == 'sex') {
      if (sumPos > sumNeg)
        return { "Feature": "Мужской", "Confidence": sumPos / fragmentsCount };
      return { "Feature": "Женский", "Confidence": sumNeg / fragmentsCount };
    }

    if (feature == 'age') {
      if (sumPos > sumNeg)
        return { "Feature": "Взрослый", "Confidence": sumPos / fragmentsCount };
      return { "Feature": "Пожилой", "Confidence": sumNeg / fragmentsCount };
    }

    if (feature == 'mood') {
      if (sumPos > sumNeg)
        return { "Feature": "Cпокоен", "Confidence": sumPos / fragmentsCount };
      return { "Feature": "Расстроен", "Confidence": sumNeg / fragmentsCount };
    }

    if (feature == 'temp') {
      if (sumPos > sumNeg)
        return { "Feature": "Быстрый темп", "Confidence": sumPos / fragmentsCount };
      return { "Feature": "Медленный темп", "Confidence": sumNeg / fragmentsCount };
    }
  }
}

class AudioDialogDescriptor {
  Phrases: Phrase[];
}

class Phrase {
  Text: string;
  AuthorId: string;
  StartingSecond: number;
  EndingSecond: number;
  Confidence: string;
}

class Speacker {
  Sex: FeatureValue;
  Age: FeatureValue;
  Temp: FeatureValue;
  Mood: FeatureValue;
}

class FeatureValue {
  Feature: string;
  Confidence: number;
}