'reach 0.1';

const [ isFingers, ONE, TWO, THREE, FOUR, FIVE ] = makeEnum(5);
const [ isGuess, TWOG, THREEG, FOURG, FIVEG, SIXG, SEVENG, EIGHTG, NINEG, TENG ] = makeEnum(9);
const [ isOutcome, K_WINS, DRAW, M_WINS ] = makeEnum(3);


const winner = (fingersM, fingersK, guessM, guessK) => { 
  if ( guessM == guessK ) 
   {
    const myoutcome = DRAW; 
    return myoutcome;
} else {
  if ( ((fingersM + fingersK) == guessM ) ) {
    const myoutcome = M_WINS;
    return myoutcome;
  } 
    else {
      if (  ((fingersM + fingersK) == guessK)) {
        const myoutcome = K_WINS;
        return myoutcome;
    } 
      else {
        const myoutcome = DRAW;
        return myoutcome;
      }
    
    }
  }
};



forall(UInt, fingersM =>
  forall(UInt, fingersK =>
    forall(UInt, guessM =>
      forall(UInt, guessK =>
    assert(isOutcome(winner(fingersM, fingersK, guessM, guessK)))))));


forall(UInt, (fingerM) =>
  forall(UInt, (fingerK) =>       
    forall(UInt, (guess) =>
      assert(winner(fingerM, fingerK, guess, guess) == DRAW))));    


const Player =
      { ...hasRandom,
        getFingers: Fun([], UInt),
        getGuess: Fun([UInt], UInt),
        seeWinning: Fun([UInt], Null),
        seeOutcome: Fun([UInt], Null) ,
        informTimeout: Fun([], Null)
       };
  
const Marija =
        { ...Player,
          wager: UInt, 
          ...hasConsoleLogger
        };

const Katarina =
        { ...Player,
          acceptWager: Fun([UInt], Null),
          ...hasConsoleLogger           
        };
const DEADLINE = 30; 

export const main =
  Reach.App(
    {},
    [Participant('Marija', Marija), Participant('Katarina', Katarina)],
    (M, K) => {
        const informTimeout = () => {
          each([M, K], () => {
            interact.informTimeout(); }); };
      M.only(() => {
        const wager = declassify(interact.wager); });
      M.publish(wager)
        .pay(wager);
      commit();   

      K.only(() => {
        interact.acceptWager(wager); });
      K.pay(wager)
        .timeout(relativeTime(DEADLINE), () => closeTo(M, informTimeout));

      var outcome = DRAW;      
      invariant(balance() == 2 * wager && isOutcome(outcome) );
   
      while ( outcome == DRAW ) {
        commit();
        M.only(() => {    
          const _fingersM = interact.getFingers();
          const _guessM = interact.getGuess(_fingersM);  
   
          interact.log(_fingersM);  
  
                      
          const [_commitM, _saltM] = makeCommitment(interact, _fingersM);
          const commitM = declassify(_commitM);        
          const [_guessCommitM, _guessSaltM] = makeCommitment(interact, _guessM);
          const guessCommitM = declassify(_guessCommitM);   
      });
     
        M.publish(commitM)
          .timeout(relativeTime(DEADLINE), () => closeTo(K, informTimeout));
        commit();    

        M.publish(guessCommitM)
          .timeout(relativeTime(DEADLINE), () => closeTo(K, informTimeout));
          ;
        commit();

        unknowable(K, M(_fingersM, _saltM));
        unknowable(K, M(_guessM, _guessSaltM));

        K.only(() => {

          const _fingersK = interact.getFingers();

          const _guessK = interact.getGuess(_fingersK);

          const fingersK = declassify(_fingersK); 
          const guessK = declassify(_guessK);  

          });

        K.publish(fingersK)
          .timeout(relativeTime(DEADLINE), () => closeTo(M, informTimeout));
        commit();
        K.publish(guessK)
          .timeout(relativeTime(DEADLINE), () => closeTo(M, informTimeout));
          ;
        
        commit();

        M.only(() => {
          const [saltM, fingersM] = declassify([_saltM, _fingersM]); 
          const [guessSaltM, guessM] = declassify([_guessSaltM, _guessM]); 

        });
        M.publish(saltM, fingersM)
          .timeout(relativeTime(DEADLINE), () => closeTo(K, informTimeout));

        checkCommitment(commitM, saltM, fingersM);
        commit();

        M.publish(guessSaltM, guessM)
        .timeout(relativeTime(DEADLINE), () => closeTo(K, informTimeout));
        checkCommitment(guessCommitM, guessSaltM, guessM);

        commit();
      
        M.only(() => {        
          const WinningNumber = fingersM + fingersK;
          interact.seeWinning(WinningNumber);
        });
     
        M.publish(WinningNumber)
        .timeout(relativeTime(DEADLINE), () => closeTo(M, informTimeout));

        outcome = winner(fingersM, fingersK, guessM, guessK);
        continue; 
       
      }

      assert(outcome == M_WINS || outcome == K_WINS);

      transfer(2 * wager).to(outcome == M_WINS ? M : K);
      commit();
 
      each([M, K], () => {
        interact.seeOutcome(outcome); })
      exit(); });