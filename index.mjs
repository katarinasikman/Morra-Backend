import {loadStdlib} from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

(async () =>{
  const startingBalance = stdlib.parseCurrency(10);

  const accMarija = await stdlib.newTestAccount(startingBalance);
  const accKatarina = await stdlib.newTestAccount(startingBalance);

  const fmt = (x) => stdlib.formatCurrency(x, 4);
  const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
  const beforeMarija = await getBalance(accMarija);
  const beforeKatarina = await getBalance(accKatarina);

  const ctcMarija = accMarija.contract(backend);
  const ctcKatarina = accKatarina.contract(backend, ctcMarija.getInfo());

  const FINGERS = [1, 2, 3, 4, 5];
  const GUESS = [2, 3, 4, 5, 6, 7, 8, 9, 10];
  const OUTCOME = ['Marija wins', 'Draw', 'Katarina wins'];

  const Player = (Who) => ({
    ...stdlib.hasRandom,
    getFingers: async () => {
      const fingers = Math.floor(Math.random() * 5);
      console.log('--------------------------');
      console.log(`${Who} shoots ${FINGERS[fingers]} fingers`);
      if(Math.random() <= 0.01){
        for(let i = 1; i < 5; i++){
          console.log(` ${Who} takes their sweet time sending it back...` );
          await stdlib.wait(1);
        }
      }
      return fingers;
    },

    getGuess: async (fingers) => {
      const guess = Math.floor(Math.random() * 5) + FINGERS[fingers];
      if(Math.random() <= 0.01){
        for(let i=2; i < 10; i++){
          console.log(` ${Who} takes their sweet time sending it back...` );
          await stdlib.wait(1);
        }
      }
      console.log(`${Who} guessed total of ${guess}`);
      return guess;
    },
    seeWinning: (winningNumber) => {
      console.log(`Acutal total fingers thrown: ${winningNumber}`);
    },
    seeOutcome: (outcome) => {
      console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
    },
    informTimeout: () => {
      console.log(`${Who} observed a timeout`);
    },
  });

  await Promise.all([
    backend.Marija(ctcMarija, {
      ...Player('Marija'),
      wager: stdlib.parseCurrency(5),
      ...stdlib.hasConsoleLogger,
    }),
    backend.Katarina(ctcKatarina, {
      ...Player('Katarina'),
      acceptWager: (amt) => {
        console.log(`--------------------------------`);
        console.log(`Katarina accepts the wager of ${fmt(amt)}.`);
      },
      ...stdlib.hasConsoleLogger,
    }),
  ]);

  const afterMarija = await getBalance(accMarija);
  const afterKatarina = await getBalance(accKatarina);

  console.log(`Marija went from ${beforeMarija} to ${afterMarija}`);
  console.log(`Katarina went from ${beforeKatarina} to ${afterKatarina}`);
}) ();
