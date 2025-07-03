# from flask import Flask, request, jsonify
# from flask_cors import CORS
# import torch
# from diffusers import StableDiffusionImg2ImgPipeline
# from PIL import Image
# import io
# import base64
# import os
# import logging

# # Set up logging
# logging.basicConfig(level=logging.INFO)
# logger = logging.getLogger(__name__)

# app = Flask(__name__)
# CORS(app)

# logger.info("Initializing Stable Diffusion...")

# try:
#     # Initialize the Stable Diffusion pipeline for CPU
#     model_id = "runwayml/stable-diffusion-v1-5"
    
#     logger.info("Loading model (this may take a few minutes)...")
    
#     # Load the pipeline with CPU optimizations
#     pipe = StableDiffusionImg2ImgPipeline.from_pretrained(
#         model_id,
#         torch_dtype=torch.float32,  # Use float32 for CPU
#         use_safetensors=True,
#         low_cpu_mem_usage=True
#     )
    
#     # Optimize for CPU
#     pipe.enable_attention_slicing()
#     pipe.to("cpu")

    
#     logger.info("Stable Diffusion pipeline loaded successfully!")

# except Exception as e:
#     logger.error(f"Error loading pipeline: {str(e)}")
#     raise

# @app.route('/generate', methods=['POST'])
# def generate_design():
#     try:
#         # Get the image file from the request
#         image_file = request.files['image']
#         theme = request.form.get('theme', 'modern')
#         prompt = request.form.get('prompt', '')
        
#         logger.info(f"Processing request - Theme: {theme}, Prompt: {prompt}")
        
#         # Read and process the image
#         image = Image.open(image_file)
        
#         # Prepare the prompt
#         full_prompt = f"interior design, {theme} style, {prompt}, high quality, detailed, professional photography"
#         negative_prompt = "low quality, blurry, distorted, unrealistic, amateur"
        
#         logger.info("Generating image...")
#         # Generate the image with reduced steps for faster CPU processing
#         result = pipe(
#             prompt=full_prompt,
#             negative_prompt=negative_prompt,
#             image=image,
#             strength=0.75,
#             guidance_scale=7.5,
#             num_inference_steps=30  # Reduced steps for faster processing
#         ).images[0]
        
#         logger.info("Image generation complete!")
        
#         # Convert the result to base64
#         buffered = io.BytesIO()
#         result.save(buffered, format="PNG")
#         img_str = base64.b64encode(buffered.getvalue()).decode()
        
#         return jsonify({
#             'success': True,
#             'image': img_str
#         })
        
#     except Exception as e:
#         logger.error(f"Error during generation: {str(e)}")
#         return jsonify({
#             'success': False,
#             'error': str(e)
#         }), 500

# if __name__ == '__main__':
#     logger.info("Starting server on http://localhost:5000")
#     app.run(host='0.0.0.0', port=5000) 