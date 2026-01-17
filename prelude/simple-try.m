(macro try (call body catcher)
  `(let ((result (safe ,call))) 
    (if result.success ,body ,catcher)))










